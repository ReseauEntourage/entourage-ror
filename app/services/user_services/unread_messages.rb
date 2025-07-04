module UserServices
  class UnreadMessages
    def initialize(user:)
      @user = user
    end

    def number_of_unread_messages
      unread_conversations.count
    end

    def number_of_unread_for_joinable_types joinable_types
      JoinRequest.where(user_id: user.id, joinable_type: joinable_types)
        .with_unread_messages
        .pluck(:joinable_id)
        .uniq
        .count
    end

    def unread_by_group_type
      unreads = unread_conversations_by_group_type

      {
        actions: unreads.filter { |message| message[1] == 'action' }.count,
        outings: unreads.filter { |message| message[1] == 'outing' }.count,
        conversations: unreads.filter { |message| message[1] == 'conversation' }.count,
      }
    end

    # this method can be expensive, use it wisely
    def unread_conversations
      JoinRequest.where(user_id: user.id, joinable_type: :Entourage)
        .joins(:entourage)
        .where("entourages.group_type = 'conversation'")
        .with_unread_messages
        .pluck(:joinable_id)
        .uniq
    end

    def unread_conversations_by_group_type
      @unread_conversations_by_group_type ||= JoinRequest.where(user_id: user.id, joinable_type: :Entourage)
        .with_unread_messages
        .joins(:entourage)
        .pluck(:joinable_id, :group_type)
        .uniq
    end

    private
    attr_reader :user
  end
end
