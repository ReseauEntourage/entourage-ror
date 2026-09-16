module V1
  class ChatMessageWebsocketSerializer < V1::ChatMessageSerializer
    attribute :reactions
    attribute :post_id

    def post_id
      object.parent_id
    end

    def reactions
      object.reactions.summary
    end
  end
end
