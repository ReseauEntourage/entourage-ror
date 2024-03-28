module Onboarding
  module ChatMessagesService
    MIN_DELAY = 5.hours
    ACTIVE_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    ACTIVE_HOURS = '09:00'..'18:30'

    def self.deliver_welcome_message
      now = Time.zone.now
      return unless now.strftime('%A').in?(ACTIVE_DAYS)
      return unless now.strftime('%H:%M').in?(ACTIVE_HOURS)

      User.where(id: user_ids).find_each do |user|
        begin
          Raven.user_context(id: user&.id)

          moderation_area = ModerationServices.moderation_area_for_user_with_default(user)
          author = moderation_area.interlocutor_for_user(user)

          if conversation = conversation_with([author.id, user.id])
            join_request = JoinRequest.find_by(joinable: conversation, user: author, status: :accepted)
            chat_message_exists = conversation.chat_messages.where(message_type: :text).exists?
          else
            conversation = ConversationService.build_conversation(participant_ids: [author.id, user.id], creator_id: author.id)
            join_request = conversation.join_requests.to_a.find { |r| r.user_id == author.id }
            chat_message_exists = false
          end

          if chat_message_exists
            Event.track('onboarding.chat_messages.welcome.skipped', user_id: user.id)
            next
          end

          variant = user.goal || :goal_not_known

          messages = [
            moderation_area["welcome_message_1_#{variant}"]
          ].map(&:presence).compact

          next if messages.empty?

          first_name = UserPresenter.format_first_name user.first_name
          interlocutor = ModerationServices.moderator_for_user(user)

          messages.each do |message|
            message = message.gsub(/\{\{\s*first_name\s*\}\}/, first_name)
            message = message.gsub(/\{\{\s*interlocutor\s*\}\}/, interlocutor.first_name) if interlocutor.present?

            builder = ChatServices::ChatMessageBuilder.new(
              user: author,
              joinable: conversation,
              join_request: join_request,
              params: {content: message}
            )

            success = true
            builder.create do |on|
              on.failure do |message|
                success = false
                raise ActiveRecord::RecordNotSaved.new("Failed to save the record", message)
              end
            end

            if success
              Event.track('onboarding.chat_messages.welcome.sent', user_id: user.id)
              join_request.update_column(:archived_at, Time.zone.now)
            end
          end

        rescue => e
          Raven.capture_exception(e)
        end
      end
    end

    def self.user_ids
      User.where(community: :entourage, deleted: false)
        .with_event('onboarding.profile.first_name.entered', :name_entered)
        .with_event('onboarding.profile.postal_code.entered', :postal_code_entered)
        .without_event('onboarding.chat_messages.welcome.sent')
        .without_event('onboarding.chat_messages.welcome.skipped')
        .where("greatest(name_entered.created_at, postal_code_entered.created_at) <= ?", MIN_DELAY.ago)
        .pluck(:id)
    end

    def self.conversation_with participant_ids
      Entourage.find_by(
        uuid_v2: ConversationService.hash_for_participants(participant_ids, validated: false)
      )
    end
  end
end
