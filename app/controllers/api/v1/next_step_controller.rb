module Api
  module V1
    class NextStepController < Api::V1::BaseController
      def show
        user_next_step = NextStepServices::SuggestionSelector.new(user: current_user).call

        if user_next_step.nil?
          return render json: { next_step: nil }, status: 200
        end

        suggestion = user_next_step.next_step_suggestion

        render json: {
          next_step: {
            id: user_next_step.id,
            suggestion_type: suggestion.suggestion_type,
            title: suggestion.title_for(current_user),
            reason: suggestion.reason_for(current_user),
            cta_label: suggestion.cta_label,
            cta_action: suggestion.cta_action,
            expires_at: user_next_step.expires_at
          }
        }, status: 200
      end

      def complete
        user_next_step = UserNextStep.active_status.find_by(id: params[:id], user: current_user)

        if user_next_step.nil?
          return render_error(code: 'NOT_FOUND', message: 'Next step not found', status: 404)
        end

        user_next_step.complete!
        render json: { message: 'Next step completed' }, status: 200
      end

      def dismiss
        user_next_step = UserNextStep.active_status.find_by(id: params[:id], user: current_user)

        if user_next_step.nil?
          return render_error(code: 'NOT_FOUND', message: 'Next step not found', status: 404)
        end

        user_next_step.dismiss!
        render json: { message: 'Next step dismissed' }, status: 200
      end

      def tap_push
        new_options = (current_user.options || {}).dup
        new_options['push_count_without_tap'] = 0
        current_user.update_columns(options: new_options)
        render json: { message: 'Push tap recorded' }, status: 200
      end
    end
  end
end
