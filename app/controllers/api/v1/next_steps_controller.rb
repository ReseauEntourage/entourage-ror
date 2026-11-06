module Api
  module V1
    # « Votre prochain pas » (EN-9473): the hero, the "others", ignoring the hero,
    # and the interactions the apps report.
    class NextStepsController < Api::V1::BaseController
      # GET /api/v1/next_steps/current
      def current
        render json: { next_step: serialize(service.call) }
      end

      # GET /api/v1/next_steps/others
      def others
        need_title = NextSteps::Need.for(current_user)&.title

        render json: {
          next_steps: service.others.map { |choice| ::V1::NextStepSerializer.new(choice, user: current_user, need_title: need_title).as_json }
        }
      end

      # POST /api/v1/next_steps/:id/ignore
      def ignore
        next_step = current_user.next_steps.find_by(id: params[:id])
        return render_not_found unless next_step

        render json: { next_step: serialize(service.ignore!(next_step)) }
      end

      # POST /api/v1/next_steps/interactions
      def interactions
        attributes = interaction_params

        next_step = nil
        if attributes[:placement] == 'hero'
          next_step = current_user.next_steps.find_by(id: attributes[:next_step_id])
          return render_not_found unless next_step
        end

        service.record_interaction!(
          placement: attributes[:placement],
          kind: attributes[:kind],
          next_step: next_step,
          item_kind: attributes[:item_kind],
          target_type: target_type_for(attributes[:item_kind]),
          target_id: attributes[:target_id]
        )

        head :no_content
      rescue ActiveRecord::RecordInvalid => e
        render json: { message: 'Could not record the interaction', reasons: e.record.errors.full_messages }, status: :bad_request
      end

      private

      def service
        @service ||= NextSteps::Current.new(current_user)
      end

      def serialize next_step
        ::V1::NextStepSerializer.new(next_step, user: current_user).as_json
      end

      def interaction_params
        params.require(:interaction).permit(:placement, :kind, :next_step_id, :item_kind, :target_id)
      end

      def target_type_for item_kind
        NextStep::TARGET_TYPES[item_kind] || (item_kind == 'content_path' ? 'Resource' : nil)
      end

      def render_not_found
        render json: { message: 'Could not find next_step' }, status: :not_found
      end
    end
  end
end
