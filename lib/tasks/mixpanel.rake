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

  task sync_action_zones: :environment do
    require 'typeform'
    require 'mixpanel_tools'

    CP_LENGTH = {
      'France'   => 5,
      'Belgique' => 4,
      'Suisse'   => 4
    }

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

      country = answers['68234976']
      cp = answers['68233033'].to_s

      next unless user_id.present?
      next unless country.in?(CP_LENGTH.keys)
      next unless cp.length == CP_LENGTH[country]

      {
        '$distinct_id' => user_id,
        '$set' => {
          "Zone d'action (pays)"        => country,
          "Zone d'action (code postal)" => cp,
          "Zone d'action (département)" => cp.first(2),
        }
      }
    end.compact

    MixpanelTools.batch_update(updates)
  end
end
