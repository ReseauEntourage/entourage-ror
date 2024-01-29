module V1
  module ChatMessages
    class PostSerializer < GenericSerializer
      attribute :reactions
      attribute :reaction_id

      def reactions
        object.reactions.summary
      end

      def reaction_id
        return false unless scope[:user].present?

        object.reactions.user_reaction_id(scope[:user].id)
      end

      def post_id
        nil
      end
    end
  end
end
