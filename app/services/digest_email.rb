module DigestEmail
  module TextHelper
    extend ActionView::Helpers::TextHelper
  end

  def self.delivery(user_id, group_ids, suggested_postal_code: nil, content_id: nil)
    user = User.find(Integer(user_id))

    return if user.deleted

    user_postal_code    = suggested_postal_code || user.address&.postal_code
    suggest_postal_code = suggested_postal_code.present? &&
                          suggested_postal_code != user.address&.postal_code

    return unless user_postal_code&.first(2).in?(['75', '69'])

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

    groups.select! do |g|
      g.country == 'FR' &&
      g.postal_code&.starts_with?(user_postal_code.first(2))
    end

    url_parameters = {
      utm_source: :digest_email,
      utm_medium: :email,
      utm_content: content_id
    }.compact

    campaign_name = [:digest_email, content_id].compact.join('_')

    groups = groups.map { |g| group_payload(g, url_parameters: url_parameters) }

    confirm_url =
      suggest_postal_code &&
      UserServices::AddressService.confirm_url(
        user: user, postal_code: suggested_postal_code)

    MemberMailer.mailjet_email(
      to: user,
      template_id: 662271,
      campaign_name: campaign_name,
      variables: {
        actions: groups,
        area_name: arrondissement_name(user_postal_code),
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

    location = arrondissement_name(group.postal_code)

    if group.group_type == 'outing'
      date = I18n.l group.metadata[:starts_at], format: "le %A %-d %B"
      location = "#{date}, à #{location}"
    end

    url = "#{ENV['WEBSITE_URL']}/entourages/#{group.uuid_v2}"
    url_parameters.compact!
    url += "?" + url_parameters.compact.to_query if url_parameters.any?

    {
      title: group.title,
      description: description,
      icon: icon,
      location: location,
      url: url
    }
  end

  def self.arrondissement_name postal_code
    case postal_code
    when /\A(75|69)0\d\d\z/
      arrondissement = postal_code.last(2).to_i
      arrondissement =
        if arrondissement == 1
          "1er"
        else
          "#{arrondissement}ème"
        end
      city = {
        75 => 'Paris',
        69 => 'Lyon'
      }[postal_code.first(2).to_i]
      "#{city} #{arrondissement}"
    else
      postal_code
    end
  end
end
