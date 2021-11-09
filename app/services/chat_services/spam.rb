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

      scope :spam_messages_for, -> (chat_message) {
        joins(%(
          left join chat_messages previous_messages on previous_messages.user_id = chat_messages.user_id
        ))
        .where("chat_messages.id = ?", chat_message.id)
        .where("similarity(chat_messages.content, previous_messages.content) > ?", SPAM_SIMILARITY)
        .where("previous_messages.created_at between ? and ?", chat_message.created_at - SPAM_PERIOD, chat_message.created_at)
        .group("chat_messages.id, previous_messages.messageable_type")
      }
    end

    def has_spams?
      return false unless content.present?
      return false unless messageable_type == 'Entourage'
      return false unless messageable.conversation?
      return false if metadata.present? && metadata[:conversation_message_broadcast_id].present?
      return false if user.moderator? || user.admin
      return false unless content.length > SPAM_MIN_LENGTH

      ChatMessage.spam_messages_for(self).length > SPAM_MIN_OCCURRENCES
    end
  end
end
