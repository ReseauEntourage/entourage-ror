module ChatServices
  # A message is considered a spam if:
  #  - it has a 0.7 similarity with at least 5 other messages (of the same user) sent in the last 7 days
  #  - it has at least 10 characters
  #  - the similar messages and this message are sent in different conversations
  #  - the user is neither a moderator nor an admin
  #  - the messages are not a broadcast (should not be relevant since the broadcasts are sent by moderators or admins)
  module Spam
    extend ActiveSupport::Concern

    included do
      SPAM_SIMILARITY = 0.7
      SPAM_MIN_LENGTH = 10
      SPAM_MIN_OCCURRENCES = 5
      SPAM_PERIOD = 7.days

      scope :spam_entourages_for, -> (chat_message) {
        select('previous_messages.messageable_type, previous_messages.messageable_id')
        .joins(%(
          left join chat_messages previous_messages
            on previous_messages.user_id = chat_messages.user_id
            and previous_messages.id <> chat_messages.id
        ))
        .where('chat_messages.id = ?', chat_message.id)
        .where('similarity(chat_messages.content, previous_messages.content) > ?', SPAM_SIMILARITY)
        .where('previous_messages.created_at between ? and ?', chat_message.created_at - SPAM_PERIOD, chat_message.created_at)
        .group('chat_messages.id, previous_messages.messageable_type, previous_messages.messageable_id')
      }
    end

    def spams
      @spams ||= begin
        return [] unless content.present?
        return [] unless content.length > SPAM_MIN_LENGTH
        return [] unless messageable_type == 'Entourage'
        return [] unless messageable.conversation?
        return [] if metadata.present? && metadata[:conversation_message_broadcast_id].present?
        return [] if user.moderator? || user.admin

        ChatMessage.spam_entourages_for(self)
      end
    end

    def has_spams?
      spams.length >= SPAM_MIN_OCCURRENCES
    end

    def check_spam!
      if has_spams? && UserHistory.spam_not_reported?(self)
        SlackServices::SignalSpam.new(spam_user: user, content: content).notify

        UserHistory.create({
          user_id: user_id,
          updater_id: nil,
          kind: 'spam-detection',
          metadata: {
            messageable_id: messageable_id,
            messageable_type: 'Entourage'
          }
        })
      end
    end
  end
end
