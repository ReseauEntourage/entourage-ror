module UserServices
  class UnreadMessages
    def initialize(user:)
      @user = user
    end

    def number_of_unread_messages
      unread_conversations.uniq.count
    end

    def unread_by_group_type
      unreads = (unread_conversations_by_group_type + unread_invitations_by_group_type).uniq

      {
        actions: unreads.filter { |message| message[1] == 'action' }.count,
        outings: unreads.filter { |message| message[1] == 'outing' }.count,
        conversations: unreads.filter { |message| message[1] == 'conversation' }.count,
      }
    end

    def unread_conversations
      JoinRequest.where(user_id: user.id, joinable_type: :Entourage)
        .with_unread_messages
        .pluck(:joinable_id)
        .uniq
    end

    def unread_conversations_by_group_type
      JoinRequest.where(user_id: user.id, joinable_type: :Entourage)
        .with_unread_messages
        .joins(:entourage)
        .pluck(:joinable_id, :group_type)
        .uniq
    end

    def unread_invitations
      EntourageInvitation.where(invitee_id: user.id, status: :pending)
        .pluck(:invitable_id)
        .uniq
    end

    def unread_invitations_by_group_type
      EntourageInvitation.where(invitee_id: user.id, status: :pending)
        .joins(:invitable)
        .pluck(:invitable_id, :group_type)
        .uniq
    end

    private
    attr_reader :user
  end
end
