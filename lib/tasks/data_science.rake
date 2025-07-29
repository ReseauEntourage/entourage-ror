namespace :data_science do
  task export: :environment do
    output_path = 'data_export'
    options = {
      col_sep: "\t",
      row_sep: "\r\n"
    }
    FileUtils.mkdir_p output_path
    FileUtils.cd output_path

    users = User.where(community: :entourage, validation_status: :validated)

    CSV.open('users.csv', 'wb', options) do |csv|
      csv.puts [
        :id,
        :created_at,
        :first_sign_in_at,
        :last_sign_in_at,
        :has_email,
        :country,
        :postal_code,
        :email_domain,
        :user_type,
        :accepts_emails,
        :deleted
      ]

      unsubscribes = EmailPreference.for_category(:default).where(subscribed: false).pluck(:user_id)

      users.includes(:address).find_each do |user|
        csv.puts [
          user.id,
          user.created_at.to_date,
          user.first_sign_in_at&.to_date,
          user.last_sign_in_at&.to_date,
          user.email.present?,
          user.address&.country,
          user.address&.postal_code,
          user.email&.split('@')&.last&.squish&.gsub(/\-\d{4}-\d\d-\d\d.*/, '')&.presence,
          user.user_type,
          !unsubscribes.include?(user.id),
          user.deleted
        ]
      end
    end

    CSV.open('sessions.csv', 'wb', options) do |csv|
      csv.puts [
        :user_id,
        :date
      ]

      SessionHistory
        .joins(:user).merge(users)
        .select(:user_id, :date).distinct
        .order(:date, :user_id)
        .each do |session|
          csv.puts [
            session.user_id,
            session.date
          ]
        end
    end

    groups = Entourage.where(group_type: [:action, :outing, :conversation]).where.not(status: :blacklisted)

    CSV.open('groups.csv', 'wb', options) do |csv|
      csv.puts [
        :id,
        :type,
        :title,
        :description,
        :created_at,
        :user_id,
        :country,
        :postal_code,
        :action_offer_or_demand,
        :display_category,
        :category,
        :author_type,
        :recipient_type,
        :outcome_reported_at,
        :outcome,
        :success_reason,
        :failure_reason,
        :status,
        :event_date
      ]

      groups
        .joins(:user).merge(users)
        .includes(:moderation)
        .find_each do |group|
          type =
            if group.display_category == 'event' || group.group_type == 'outing'
              :event
            else
              group.group_type.to_sym
            end

          offer_or_demand =
            if type != :action
              nil
            elsif group.entourage_type == 'contribution'
              :offer
            else
              :demand
            end

          csv.puts [
            group.id,
            type,
            group.title.presence&.squish,
            group.description.presence&.squish,
            group.created_at.to_date,
            group.user_id,
            group.country.presence,
            group.postal_code.presence,
            offer_or_demand,
            (group.display_category unless type == :event),
            group.moderation&.action_type.presence,
            group.moderation&.action_author_type.presence,
            group.moderation&.action_outcome_reported_at.presence,
            group.moderation&.action_outcome.presence,
            group.moderation&.action_success_reason.presence,
            group.moderation&.action_failure_reason.presence,
            group.status,
            (group.metadata[:starts_at].to_date if group.group_type == 'outing')
          ]
        end
    end

    CSV.open('users_groups.csv', 'wb', options) do |csv|
      csv.puts [
        :user_id,
        :group_id,
        :created_at,
        :status,
        :last_read_at
      ]

      scope = JoinRequest
        .where(status: [:pending, :accepted])
        .joins(:user).merge(users)
        .joins(:entourage).merge(groups)
        .joins(entourage: :user).where(users_entourages: users.where_values_hash)

      scope.find_each do |request|
        csv.puts [
          request.user_id,
          request.joinable_id,
          (request.requested_at || request.created_at).to_date,
          request.status,
          request.last_message_read&.to_date
        ]
      end
    end

    CSV.open('messages.csv', 'wb', options) do |csv|
      csv.puts [
        :user_id,
        :group_id,
        :created_at
      ]

      ChatMessage
        .where(message_type: :text)
        .joins(:user).merge(users)
        .joins("join entourages on messageable_type = 'Entourage' and entourages.id = messageable_id").merge(groups)
        .joins('join users users_entourages on users_entourages.id = entourages.user_id').where(users_entourages: users.where_values_hash)
        .find_each do |message|
          csv.puts [
            message.user_id,
            message.messageable_id,
            message.created_at.to_date
          ]
        end
    end
  end
end
