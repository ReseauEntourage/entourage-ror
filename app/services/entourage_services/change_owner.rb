module EntourageServices
  class ChangeOwner
    USER_NOT_FOUND = "L'utilisateur n'a pas pu être trouvé"
    INVALID_JOINABLE = "Le créateur ne peut être changé que pour les actions épinglées, les événements ou les groupes de voisinage"

    attr_reader :user

    def initialize joinable
      @joinable = joinable
    end

    # 1. sets all joinable join_requests as member/participant
    # 2. ensure user_id has a join_request for joinable
    # 3. sets user_id as the organizer/creator for joinable
    # 4. create a chat_message to let people know about this new organizer/creator
    def to user_id, message
      return yield false, USER_NOT_FOUND unless user = User.find(user_id)
      return yield false, INVALID_JOINABLE unless joinable_is_valid?

      owner_join_request = JoinRequest.where(joinable: @joinable, user_id: user_id, role: member_type).first_or_create

      ApplicationRecord.transaction do
        creator_join_requests.update_all(role: member_type)

        owner_join_request.update(status: :accepted, role: creator_type)

        @joinable.update_attribute(:user_id, user_id)
      end

      if message.present?
        ChatServices::ChatMessageBuilder.new(
          user: user,
          joinable: @joinable,
          join_request: owner_join_request,
          params: {
            message_type: :text,
            content: message,
          }
        ).create
      end

      yield true
    end

    private

    def creator_join_requests
      @joinable.join_requests.where("role in (?)", [:creator, :organizer])
    end

    def joinable_is_valid?
      neighborhood? || outing?
    end

    def creator_type
      return :organizer if outing?

      :creator
    end

    def member_type
      return :participant if outing?

      :member
    end

    def outing?
      @joinable.is_a?(Entourage) && @joinable.outing?
    end

    def neighborhood?
      @joinable.is_a?(Neighborhood)
    end
  end
end
