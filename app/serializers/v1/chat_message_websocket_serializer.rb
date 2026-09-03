module V1
  class ChatMessageWebsocketSerializer < V1::ChatMessageSerializer
    attribute :reactions

    def reactions
      object.reactions.summary
    end
  end
end
