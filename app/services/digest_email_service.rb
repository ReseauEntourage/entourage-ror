require Rails.root.join('config/digest_email_config')

module DigestEmailService
  UNSUBSCRIBE_CATEGORY = :digest_email

  module TextHelper
    extend ActionView::Helpers::TextHelper
  end

  def self.config
    DigestEmailConfig
  end

  def self.schedule_delivery!
    current_last_delivery_at = DigestEmail.maximum(:deliver_at)

    return if current_last_delivery_at.present? &&
              current_last_delivery_at >= 2.days.from_now

    next_delivery_at = next_delivery(
      day: config.schedule.day,
      time: config.schedule.time,
      previous_delivery: current_last_delivery_at,
      min_interval: config.schedule.min_interval
    )

    DigestEmail.create!(deliver_at: next_delivery_at, status: :scheduled)
  end

  def self.deliver_scheduled!
    DigestEmail.to_deliver.sorted.each do |email|
      AsyncService.new(self).deliver(email)
    end
  end

  def self.deliver_test email, user_id:, department:
    department_code = department.to_s

    group_ids = group_ids_for(
      email, city: department_code, date: email.deliver_at)

    if group_ids.empty?
      return :no_groups
    end

    user_delivery = delivery(
      User.find(user_id),
      group_ids,
      suggested_postal_code: "#{department_code}002", # to have a subject that matches
      content_id: :test
    )

    if user_delivery.nil?
      return :blocked_delivery
    end

    user_delivery.deliver_now

    return :success
  end

  def self.deliver email
    now = Time.zone.now

    Sentry.set_extras(
      digest_email_id: email&.id,
      digest_email_data: email&.data,
      now: now
    )

    if email.status != 'scheduled'
      raise "email status must be 'scheduled' (got '#{email.status}')"
    end

    if email.deliver_at.future?
      raise "email deliver_at must be past (got '#{email.deliver_at}')"
    end

    email.update_column(:status, :delivering)
    email.data['delivery_started_at'] = now.iso8601
    email.save

    city_group_ids = {}

    config.cities.values.each do |department_code|
      department_code = department_code.to_s

      Sentry.set_extras(department_code: department_code)

      city_group_ids[department_code] = group_ids_for(
        email, city: department_code, date: now)

      next if city_group_ids[department_code].empty?

      users_for_city(department_code).includes(:address).find_each do |user|
        begin
          Sentry.set_user(id: user&.id)

          user_delivery = delivery(
            user,
            city_group_ids[department_code],
            suggested_postal_code: nil,
            content_id: "#{department_code}_#{email.deliver_at.to_date}"
          )

          next if user_delivery.nil?

          user_delivery.deliver_now

        rescue => e
          Sentry.capture_exception(e)
        end
      end
    end

    email.update_column(:status, :delivered)
    email.data['delivery_ended_at'] = Time.zone.now.iso8601
    email.save
  end

  def self.users_for_city department_code
    User
      .where(community: :entourage)
      .joins(:address)
      .where("country = 'FR'")
      .where("substring(postal_code for 2) = ?", department_code.to_s)
      .where(last_sign_in_at: 6.months.ago.midnight..Time.now)
      .accepts_email_category(UNSUBSCRIBE_CATEGORY)
      .where(deleted: false)
      .where("email <> ''")
  end

  def self.events_for_city department_code, date:
    Entourage
      .where(community: :entourage)
      .where(group_type: :outing)
      .where("country = 'FR'")
      .where("substring(postal_code for 2) = ?", department_code.to_s)
      .where("metadata->>'ends_at' >= ?", date.in_time_zone.advance(days: 2).midnight)
      .order("metadata->>'starts_at'")
      .limit(5)
  end

  def self.group_ids_for email, city:, date:
    department_code = city.to_s
    selected_groups = email.data.dig('group_ids', department_code) || []
    automatic_events = events_for_city(department_code, date: date).pluck(:id)
    (automatic_events + selected_groups).uniq
  end

  def self.next_delivery day:, time:, previous_delivery:, min_interval:
    if previous_delivery
      unless min_interval.is_a?(ActiveSupport::Duration)
        raise "min_interval must be an ActiveSupport::Duration"
      end

      starting_point = previous_delivery.in_time_zone.midnight + min_interval
    else
      starting_point = Time.now
    end

    if starting_point.past?
      starting_point = Time.now
    end

    starting_point = starting_point.in_time_zone

    date = starting_point
      .advance(days: (7 - starting_point.days_to_week_start(day)) % 7)

    hour, min = Array(time)
    datetime = date.change(hour: hour, min: min)

    if datetime.past?
      datetime = datetime.advance(weeks: 1)
    end

    datetime
  end

  def self.delivery(user, group_ids, suggested_postal_code: nil, content_id: nil)
    return if user.deleted

    user_postal_code    = suggested_postal_code || user.address&.postal_code
    suggest_postal_code = suggested_postal_code.present? &&
                          suggested_postal_code != user.address&.postal_code

    user_group_data_cache_key = [group_ids, user.community.slug, content_id]
    group_data_cache_key, group_data_cache_value = @group_data_cache

    if user_group_data_cache_key == group_data_cache_key
      groups = group_data_cache_value
    else
      group_ids = group_ids
        .map(&:presence)
        .compact
        .map { |group_id| Integer(group_id) }
        .uniq

      groups =
        Entourage
        .where(community: user.community)
        .where(status: [:open, :closed])
        .where(group_type: [:action, :outing])
        .where(id: group_ids)
        .sort_by { |g| group_ids.index(g.id) }

      url_parameters = {
        utm_source: :digest_email,
        utm_medium: :email,
        utm_content: content_id
      }.compact

      groups = groups.map { |g| group_payload(g, url_parameters: url_parameters) }
      @group_data_cache = [user_group_data_cache_key, groups]
    end

    campaign_name = [:digest_email, content_id].compact.join('_')

    confirm_url =
      suggest_postal_code &&
      UserServices::AddressService.confirm_url(
        user: user, postal_code: suggested_postal_code)

    MemberMailer.mailjet_email(
      to: user,
      template_id: 662271,
      campaign_name: campaign_name,
      unsubscribe_category: UNSUBSCRIBE_CATEGORY.to_s,
      deliver_only_once: content_id == :test ? false : true,
      variables: {
        actions: groups,
        area_name: arrondissement_or_city_name(user_postal_code),
        area_name_with_preposition: city_name_with_preposition(user_postal_code),
        confirm_url: confirm_url
      }
    )
  end

  def self.group_payload group, url_parameters: {}
    participant_count = group.join_requests.accepted.count
    description = TextHelper.pluralize(participant_count, "participant")

    icon =
      case group.group_type
      when 'outing' then :event
      else group.display_category
      end

    location = arrondissement_name_or_postal_code(group.postal_code)

    if group.group_type == 'outing'
      date =
        if group.metadata[:starts_at].midnight == group.metadata[:ends_at].midnight
          I18n.l group.metadata[:starts_at], format: "le %A %-d %B"
        else
          [I18n.l(group.metadata[:starts_at], format: "du %A %-d %B "),
           I18n.l(group.metadata[:ends_at],   format: "au %A %-d %B")].join
        end
      location = "#{date}, à #{location}"
    end

    url = group.share_url
    url_parameters.compact!
    url += "?" + url_parameters.compact.to_query if url_parameters.any?

    {
      title: group.title,
      description: description,
      icon: icon.to_s,
      location: location,
      url: url
    }
  end

  def self.city_name postal_code
    config.cities.invert[postal_code.first(2).to_i].to_s
  end

  def self.city_name_with_preposition postal_code
    city_name = self.arrondissement_or_city_name postal_code
    if city_name == 'Hauts-de-Seine'
      "dans les #{city_name}"
    else
      "à #{city_name}"
    end
  end

  def self.maybe_arrondissement_name postal_code
    case postal_code
    when '75000'
      nil
    when /\A(75|69)0\d\d\z/
      arrondissement = postal_code.last(2).to_i
      arrondissement =
        if arrondissement == 1
          "1er"
        else
          "#{arrondissement}ème"
        end

      "#{city_name(postal_code)} #{arrondissement}"
    when '75116'
      'Paris 16ème'
    else
      nil
    end
  end

  def self.arrondissement_or_city_name postal_code
    maybe_arrondissement_name(postal_code) || city_name(postal_code)
  end

  def self.arrondissement_name_or_postal_code postal_code
    maybe_arrondissement_name(postal_code) || postal_code
  end
end
