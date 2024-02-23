module V1
  module ChatMessages
    class PostSerializer < GenericSerializer
      attribute :reactions
      attribute :reaction_id
      attribute :survey_response

      def reactions
        object.reactions.summary
      end

      def reaction_id
        return false unless scope[:user].present?

        object.reactions.user_reaction_id(scope[:user].id)
      end

      def survey_response
        return unless scope[:user].present?

        object.survey_responses.response(scope[:user].id)
      end

      def post_id
        nil
      end
    end
  end
end
