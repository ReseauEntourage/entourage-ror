module Api
  module V1
    class SuggestionsController < Api::V1::BaseController
      def index
        suggestions = SuggestionServices::Generate.for_user(current_user)

        render json: {
          suggestions: {
            connection: serialize_suggestion(suggestions[:connection]),
            next_step:  serialize_suggestion(suggestions[:next_step])
          }
        }
      end

      def update
        suggestion = current_user.user_suggestions.find_by(id: params[:id])

        return render json: { message: 'not found' }, status: :not_found unless suggestion

        case params[:action_type]
        when 'actioned'
          suggestion.update!(actioned_at: Time.current)
        when 'dismissed'
          suggestion.update!(
            dismissed_at: Time.current,
            dismissed_until: 30.days.from_now
          )
        else
          return render json: { message: 'invalid action' }, status: :unprocessable_entity
        end

        render json: {
          suggestion: serialize_suggestion(suggestion)
        }
      end

      private

      def serialize_suggestion(suggestion)
        return nil unless suggestion

        V1::UserSuggestionSerializer.new(suggestion, scope: { user: current_user }).as_json
      end
    end
  end
end
