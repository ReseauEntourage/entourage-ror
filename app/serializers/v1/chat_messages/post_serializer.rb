module V1
  module ChatMessages
    class PostSerializer < GenericSerializer
      attribute :reactions
      attribute :reaction_id
      attribute :survey_response
      attribute :auto_post_from

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

      def auto_post_from
        return unless object.options.present?
        return unless object.options.key?("auto_post_type") && object.options.key?("auto_post_id")

        {
          instance_type: object.options["auto_post_type"],
          instance_id: object.options["auto_post_id"]
        }
      end

      def post_id
        nil
      end
    end
  end
end
