module EntourageServices
  class ChangeOwner
    attr_reader :user

    def initialize entourage
      @entourage = entourage
    end

    # 1. update entourage.user_id
    # 2. update join_requests creator
    # 3. create ChatMessage to inform other users
    def to user_id, message:
      return yield false, "User not found" unless user = User.find(user_id)
      return yield false, "Entourage should be an action" unless @entourage.action?
      return yield false, "Entourage should be pinned" unless @entourage.pin?

      creator_join_requests = @entourage.join_requests.where(role: :creator)

      return yield false, "Entourage should have a creator join_request" unless creator_join_requests.any?

      Entourage.transaction do
        @entourage.update_attribute(:user_id, user.id)

        creator_join_requests.each do |join_request|
          join_request.update_attribute(:user_id, user.id)
        end

        if message.present?
          ChatServices::ChatMessageBuilder.new(
            user: user,
            joinable: @entourage,
            join_request: user.join_requests.accepted.find_by!(joinable: @entourage),
            params: {
              message_type: :text,
              content: message,
            }
          ).create
        end
      end

      yield true
    end
  end
end
