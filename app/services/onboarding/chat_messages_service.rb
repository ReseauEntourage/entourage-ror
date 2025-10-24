module Onboarding
  module ChatMessagesService
    ETHICAL_CHARTER_DELAY = 2.hours
    ACTIVE_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    ACTIVE_HOURS = '09:00'..'18:30'

    def self.deliver_welcome_message
      now = Time.zone.now
      return unless now.strftime('%A').in?(ACTIVE_DAYS)
      return unless now.strftime('%H:%M').in?(ACTIVE_HOURS)

      User.where(id: welcome_message_user_ids).find_each do |user|
        begin
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

          messages.each do |message|
            message = ChatMessage.interpolate(message: message, user: user, author: author)

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
                raise ActiveRecord::RecordNotSaved.new('Failed to save the record', message)
              end
            end

            if success
              Event.track('onboarding.chat_messages.welcome.sent', user_id: user.id)
              join_request.update_column(:archived_at, Time.zone.now)
            end
          end
        rescue => e
          Rails.logger.error(e)
        end
      end
    end

    def self.welcome_message_user_ids
      User.where(community: :entourage, deleted: false)
        .with_event('onboarding.profile.first_name.entered', :name_entered)
        .with_event('onboarding.profile.postal_code.entered', :postal_code_entered)
        .without_event('onboarding.chat_messages.welcome.sent')
        .without_event('onboarding.chat_messages.welcome.skipped')
        .pluck(:id)
    end

    def self.deliver_ethical_charter
      now = Time.zone.now
      return unless now.strftime('%A').in?(ACTIVE_DAYS)
      return unless now.strftime('%H:%M').in?(ACTIVE_HOURS)

      User.where(id: ethical_charter_user_ids).find_each do |user|
        next unless author = ModerationServices.moderator_for_user(user)

        if conversation = conversation_with([author.id, user.id])
          join_request = JoinRequest.find_by(joinable: conversation, user: author, status: :accepted)
        else
          conversation = ConversationService.build_conversation(participant_ids: [author.id, user.id], creator_id: author.id)
          join_request = conversation.join_requests.to_a.find { |r| r.user_id == author.id }
        end

        ChatServices::ChatMessageBuilder.new(
          user: author,
          joinable: conversation,
          join_request: join_request,
          params: {
            content: I18n.t('onboarding.ethical_charter', locale: user.lang) % [author.first_name]
          }
        ).create do |on|
          on.success do
            Event.track('onboarding.chat_messages.ethical_charter.sent', user_id: user.id)
          end
        end
      end
    end

    def self.ethical_charter_user_ids
      # 2024-10-23 is the day when we sent this functionality to production
      User.where(community: :entourage, deleted: false, admin: false)
        .with_event('onboarding.chat_messages.welcome.sent', :welcome_sent)
        .without_event('onboarding.chat_messages.ethical_charter.sent')
        .where("welcome_sent.created_at between '2024-10-23' and ?", ETHICAL_CHARTER_DELAY.ago)
        .pluck(:id)
    end

    def self.ethical_charter_message
      I18n.t('chat_messages.ethical_charter', default: ETHICAL_CHARTER_TEMPLATE)
    end

    def self.conversation_with participant_ids
      Entourage.find_by(
        uuid_v2: ConversationService.hash_for_participants(participant_ids, validated: false)
      )
    end
  end
end
