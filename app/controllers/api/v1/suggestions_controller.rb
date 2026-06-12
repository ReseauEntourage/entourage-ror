module Api
  module V1
    class SuggestionsController < Api::V1::BaseController
      def index
        suggestions = SuggestionServices::Generate.for_user(current_user)

        render json: {
          connection: serialize_suggestion(suggestions[:connection]),
          next_step:  serialize_suggestion(suggestions[:next_step])
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

        user_info = if suggestion.suggested_user.present?
          u = suggestion.suggested_user
          address = Address.where(user_id: u.id, position: 1).first
          {
            id:          u.id,
            uuid:        u.uuid,
            first_name:  u.first_name,
            avatar_url:  u.avatar_url,
            postal_code: address&.postal_code
          }
        end

        entourage_info = if suggestion.suggested_entourage.present?
          e = suggestion.suggested_entourage
          {
            id:               e.id,
            uuid:             e.uuid,
            title:            e.title,
            group_type:       e.group_type,
            display_category: e.display_category,
            metadata:         e.metadata
          }
        end

        {
          id:                     suggestion.id,
          suggestion_type:        suggestion.suggestion_type,
          suggested_action:       suggestion.suggested_action,
          reason:                 suggestion.reason,
          reason_type:            suggestion.reason_type,
          expires_at:             suggestion.expires_at,
          suggested_user_info:    user_info,
          suggested_entourage_info: entourage_info
        }
      end
    end
  end
end
