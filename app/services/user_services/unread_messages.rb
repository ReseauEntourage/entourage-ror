module UserServices
  class UnreadMessages
    def initialize(user:)
      @user = user
    end

    def number_of_unread_messages
      (unread_conversations + unread_invitations).uniq.count
    end

    def unread_conversations
      JoinRequest.where(user_id: user.id, joinable_type: :Entourage)
        .with_unread_messages
        .pluck(:joinable_id)
        .uniq
    end

    def unread_invitations
      EntourageInvitation.where(invitee_id: user.id, status: :pending)
        .pluck(:invitable_id)
        .uniq
    end

    private
    attr_reader :user
  end
end
