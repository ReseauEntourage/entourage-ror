module Api
  module V1
    class SuggestionsController < Api::V1::BaseController

      VALID_ACTIONS = %w[actioned dismissed].freeze

      def index
        suggestions = SuggestionServices::Generate.for_user(current_user)

        render json: {
          connection: serialize_suggestion(suggestions[:connection]),
          next_step:  serialize_suggestion(suggestions[:next_step])
        }
      rescue => e
        Rails.logger.error "[SuggestionsController#index] user=#{current_user&.id} #{e.class}: #{e.message}"
        render_error(
          code: 'SUGGESTIONS_FETCH_FAILED',
          message: 'Unable to fetch suggestions',
          status: :internal_server_error
        )
      end

      def update
        suggestion = current_user.user_suggestions.find_by(id: params[:id])

        unless suggestion
          return render_error(
            code: 'SUGGESTION_NOT_FOUND',
            message: "Suggestion ##{params[:id]} not found or does not belong to current user",
            status: :not_found
          )
        end

        action_type = params[:action_type].to_s

        unless VALID_ACTIONS.include?(action_type)
          return render_error(
            code: 'INVALID_ACTION_TYPE',
            message: "action_type must be one of: #{VALID_ACTIONS.join(', ')}",
            status: :unprocessable_entity
          )
        end

        if action_type == 'actioned'
          suggestion.update!(actioned_at: Time.current)
        else
          suggestion.update!(dismissed_at: Time.current, dismissed_until: 7.days.from_now)
        end

        render json: { suggestion: serialize_suggestion(suggestion) }
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "[SuggestionsController#update] user=#{current_user&.id} suggestion=#{params[:id]} #{e.message}"
        render_error(
          code: 'SUGGESTION_UPDATE_FAILED',
          message: e.message,
          status: :unprocessable_entity
        )
      rescue => e
        Rails.logger.error "[SuggestionsController#update] user=#{current_user&.id} suggestion=#{params[:id]} #{e.class}: #{e.message}"
        render_error(
          code: 'SUGGESTION_UPDATE_ERROR',
          message: 'Unable to update suggestion',
          status: :internal_server_error
        )
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
          id:                       suggestion.id,
          suggestion_type:          suggestion.suggestion_type,
          suggested_action:         suggestion.suggested_action,
          reason:                   suggestion.reason,
          reason_type:              suggestion.reason_type,
          expires_at:               suggestion.expires_at,
          suggested_user_info:      user_info,
          suggested_entourage_info: entourage_info
        }
      rescue => e
        Rails.logger.error "[SuggestionsController#serialize] suggestion=#{suggestion&.id} #{e.class}: #{e.message}"
        nil
      end
    end
  end
end
