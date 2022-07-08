module EntourageServices
  class ChangeOwner
    attr_reader :user

    def initialize joinable
      @joinable = joinable
    end

    # 1. sets all joinable join_requests as member/participant
    # 2. ensure user_id has a join_request for joinable
    # 3. sets user_id as the organizer/creator for joinable
    # 4. create a chat_message to let people know about this new organizer/creator
    def to user_id, message:
      return yield false, "L'utilisateur n'a pas pu être trouvé" unless user = User.find(user_id)
      return yield false, "Le créateur ne peut être changé que pour les actions épinglées, les événements ou les groupes de voisinage" unless joinable_is_valid?

      ApplicationRecord.transaction do
        creator_join_requests.update_all(:role, member_type)

        owner_join_request = @joinable.where(user_id: user_id, role: member_type).first_or_create
        owner_join_request.update_attributes(status: :accepted, role: creator_type)

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
      end

      yield true
    end

    def creator_join_requests
      @joinable.join_requests.where("role in (?)", [:creator, :organizer])
    end

    def joinable_is_valid?
      @joinable.pin? || @joinable.outing? || @joinable.is_a?(Neighborhood)
    end

    def creator_type
      return :organizer if @joinable.outing?

      :creator
    end

    def member_type
      return :participant if @joinable.outing?

      :member
    end
  end
end
