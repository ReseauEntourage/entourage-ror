module V1
  class OutingHomeSerializer < V1::OutingSerializer
    attribute :posts

    def posts
      object.parent_chat_messages.ordered.limit(25).map do |chat_message|
        V1::ChatMessageHomeSerializer.new(chat_message, scope: { current_join_request: current_join_request }).as_json
      end
    end

    def metadata
      object.metadata_with_image_paths(:original).except(:$id)
    end

    private

    def current_join_request
      return unless scope[:user]

      @current_join_request ||= JoinRequest.where(joinable_id: object.id, joinable_type: :Entourage, user: scope[:user], status: :accepted).first
    end
  end
end
