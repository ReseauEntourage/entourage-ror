module V1
  module ChatMessages
    class PostSerializer < GenericSerializer
      attribute :reactions

      def reactions
        object.reactions.summary
      end

      def post_id
        nil
      end
    end
  end
end
