module ChatServices
  module PrivateConversation
    extend ActiveSupport::Concern

    included do
      ACTIVE_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
      ACTIVE_HOURS = '09:00'..'18:30'

      after_create :notify_moderator_not_available, if: :notify_moderator_not_available?
    end

    def notify_moderator_not_available
      return unless messageable

      content = I18n.t("community.chat_messages.status_update.moderator_working_hours", locale: user.lang) % [user.full_name, private_message_interlocutor.full_name]

      if messageable.chat_messages.new(user: private_message_interlocutor, content: content).save
        messageable.update_columns(working_hours_sent_at: Time.zone.now)
      end
    end

    def notify_moderator_not_available?
      return false if user.moderator?
      return false unless messageable.respond_to?(:conversation?)
      return false unless messageable.conversation?

      is_interlocutor_a_moderator? && is_moderator_working_hours? && is_notify_moderator_not_sent?
    end

    def is_interlocutor_a_moderator?
      return false unless private_message_interlocutor

      private_message_interlocutor.moderator?
    end

    def is_moderator_working_hours?
      return false unless created_at

      created_at.strftime('%A').in?(ACTIVE_DAYS) && created_at.strftime('%H:%M').in?(ACTIVE_HOURS)
    end

    def is_notify_moderator_not_sent?
      return false unless messageable

      messageable.working_hours_sent_at.blank?
    end

    def private_message_interlocutor
      return unless messageable

      @private_message_interlocutor ||= messageable.interlocutor_of(user)
    end
  end
end
