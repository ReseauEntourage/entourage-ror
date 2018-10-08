namespace :mixpanel do
  task update_user_properties: :environment do
    require 'mixpanel_tools'

    updates = MixpanelTools.get_people.map do |profile|
      # Update operations: https://mixpanel.com/help/reference/http#update-operations
      # Special/reserved props : https://help.mixpanel.com/hc/en-us/articles/115004602703-Special-or-reserved-properties
      user_id = UserServices::EncodedId.encode(profile['$distinct_id']) rescue 'invalid'
      {
        '$distinct_id' => profile['$distinct_id'],
        '$set' => {
          "user_id" => user_id
        }
      }
    end

    MixpanelTools.batch_update(updates)
  end

  task update_user_joined_actions: :environment do
    require 'mixpanel_tools'

    redis_key = 'mixpanel:update_user_joined_actions:last_join_request'
    last_join_request = Integer($redis.get(redis_key)) rescue nil
    entourage_scope = Entourage.where(country: 'FR')

    if ENV['ALL'] == 'true'
      Rails.logger.info 'scope: all join requests without restriction (ALL=true)'
      join_request_scope = JoinRequest.all
    elsif last_join_request.nil?
      Rails.logger.info 'scope: all join requests without restriction (redis key nil)'
      join_request_scope = JoinRequest.all
    else
      Rails.logger.info 'scope: join requests with id > %d (from redis)' % last_join_request
      join_request_scope = JoinRequest.where("join_requests.id > ?", last_join_request)
    end

    users = User
      .joins(join_requests: :entourage)
      .merge(join_request_scope)
      .merge(entourage_scope)
      .select(:id)
      .uniq

    updates = []

    users.find_each do |user|
      postal_codes = user.entourage_participations.merge(entourage_scope).uniq.pluck(:postal_code)
      updates.push(
        '$distinct_id' => user.id,
        '$set' => {
          "Actions rejointes (code postal)" => postal_codes.sort.map(&:to_i),
          "Actions rejointes (département)" => postal_codes.map { |cp| cp.first(2) }.uniq.sort.map(&:to_i)
        }
      )
    end

    MixpanelTools.batch_update(updates)

    Rails.logger.info "#{updates.count} updates"
    last_join_request = join_request_scope.maximum(:id)
    if last_join_request
      $redis.set(redis_key, last_join_request)
      Rails.logger.info "last_join_request: #{last_join_request}"
    end
  end

  task sync_action_zones: :environment do
    require 'typeform'
    require 'mixpanel_tools'

    def save_and_build_update user_id:, country:, postal_code:
      begin
        zone = ActionZone.find_or_create_by!(
          user_id: user_id,
          country: country,
          postal_code: postal_code
        )
      rescue ActiveRecord::RecordInvalid,
             ActiveRecord::RecordNotUnique,
             ActiveRecord::InvalidForeignKey # no user for this user_id
        return
      end

      {
        '$distinct_id' => user_id,
        '$set' => {
          "Zone d'action (pays)"        => zone.country_name,
          "Zone d'action (code postal)" => zone.postal_code,
          "Zone d'action (département)" => zone.postal_code.first(2),
        }
      }
    end

    #
    # App form
    #
    updates = Typeform.get_responses('WIg5A9').map do |response|
      answers = Typeform.answers(response)

      next unless answers['user_id'].present?

      user_id =
        if answers['user_id'].include?('@')
          User
            .where(deleted: false, email: answers['user_id'])
            .order("case when last_sign_in_at is null then 1 else 0 end, last_sign_in_at desc")
            .limit(1)
            .pluck(:id)
            .first
        else
          UserServices::EncodedId.decode(answers['user_id'])
        end

      save_and_build_update(
        user_id: user_id,
        country: answers['68234976'],
        postal_code: answers['68233033']
      )
    end.compact

    MixpanelTools.batch_update(updates)

    #
    # Email suggestion form
    #
    updates = Typeform.get_responses('ODMdxb').map do |response|
      answers = Typeform.answers(response)

      next unless answers['user_id'].present?

      user_id = UserServices::EncodedId.decode(answers['user_id'])

      save_and_build_update(
        user_id: user_id,
        country: answers['ACR7DCvtkEuM'],
        postal_code: answers['tur0a09lYRlM']
      )
    end.compact

    MixpanelTools.batch_update(updates)
  end

  task sync_addresses: :environment do
    require 'mixpanel_tools'

    current_run_at = Time.zone.now
    redis_key = 'mixpanel:sync_addresses:last_run'
    redis_date = current_run_at.to_datetime.rfc3339
    last_run_at = Time.zone.parse($redis.get(redis_key)) rescue nil

    if ENV['ALL'] == 'true'
      puts 'scope: all addresses without restriction (ALL=true)'
      addresses = Address.all
    elsif last_run_at.nil?
      puts 'scope: all addresses without restriction (redis key nil)'
      addresses = Address.all
    else
      puts 'scope: addresses with updated_at > %s (from redis)' % last_run_at
      addresses = Address.where("addresses.updated_at > ?", last_run_at)
    end

    addresses = addresses.joins(:user).merge($server_community.users).includes(:user)

    MixpanelService.sync_addresses(addresses.find_each)

    $redis.set(redis_key, redis_date)
  end
end
