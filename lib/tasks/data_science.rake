namespace :data_science do
  task export: :environment do
    output_path = 'data_export'
    FileUtils.mkdir_p output_path
    FileUtils.cd output_path

    users = User.where(community: :entourage, deleted: false, validation_status: :validated)

    CSV.open("users.csv", "wb") do |csv|
      csv.puts [
        :id,
        :created_at,
        :first_sign_in_at,
        :last_sign_in_at,
        :country,
        :postal_code
      ]

      users.includes(:address).find_each do |user|
        csv.puts [
          user.id,
          user.created_at.to_date,
          user.first_sign_in_at&.to_date,
          user.last_sign_in_at&.to_date,
          user.address&.country,
          user.address&.postal_code
        ]
      end
    end

    CSV.open("sessions.csv", "wb") do |csv|
      csv.puts [
        :user_id,
        :date
      ]

      SessionHistory.select(:user_id, :date).uniq.order(:date, :user_id).joins(:user).merge(users).each do |session|
        csv.puts [
          session.user_id,
          session.date
        ]
      end
    end

    groups = Entourage.where(group_type: [:action, :outing]).where.not(status: :blacklisted)

    CSV.open("groups.csv", "wb") do |csv|
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
        :failure_reason
      ]

      groups.joins(:user).merge(users).includes(:moderation).find_each do |group|
        type =
          if group.display_category == 'event' || group.group_type == 'outing'
            :event
          else
            :action
          end

        offer_or_demand =
          if type == :event
            nil
          elsif group.entourage_type == 'contribution'
            :offer
          else
            :demand
          end

        csv.puts [
          group.id,
          type,
          group.title,
          group.description,
          group.created_at.to_date,
          group.user_id,
          group.country,
          group.postal_code,
          offer_or_demand,
          (group.display_category unless type == :event),
          group.moderation&.action_type,
          group.moderation&.action_author_type,
          group.moderation&.action_recipient_type,
          group.moderation&.action_outcome_reported_at,
          group.moderation&.action_outcome,
          group.moderation&.action_success_reason,
          group.moderation&.action_failure_reason
        ]
      end
    end

    CSV.open("users_groups.csv", "wb") do |csv|
      csv.puts [
        :user_id,
        :group_id,
        :created_at,
        :status,
        :last_read_at
      ]

      JoinRequest.where(status: [:pending, :accepted])
                 .joins(:entourage, :user).merge(groups).merge(users)
                 .find_each do |request|
        csv.puts [
          request.user_id,
          request.joinable_id,
          request.created_at.to_date,
          request.status,
          request.last_message_read&.to_date
        ]
      end
    end

    CSV.open("messages.csv", "wb") do |csv|
      csv.puts [
        :user_id,
        :group_id,
        :created_at
      ]

      ChatMessage.where(message_type: :text)
                 .joins(:user)
                 .joins("join entourages on messageable_type = 'Entourage' and entourages.id = messageable_id")
                 .merge(groups).merge(users)
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
