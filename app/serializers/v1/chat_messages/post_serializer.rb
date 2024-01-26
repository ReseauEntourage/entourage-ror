module V1
  module ChatMessages
    class PostSerializer < GenericSerializer
      attribute :reactions
      attribute :has_reacted

      def reactions
        object.reactions.summary
      end

      def has_reacted
        return false unless scope[:user].present?

        object.reactions.user_has_reacted?(scope[:user].id)
      end

      def post_id
        nil
      end
    end
  end
end
