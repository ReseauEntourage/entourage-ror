module Api
  module V1
    module Assistant
      # Base of the routes through which the assistant acts on behalf of a user (as opposed to
      # the reads, which inherit from BaseController).
      #
      # - ASSISTANT_ACTIONS_ENABLED (false by default) switches every action off with a 503,
      #   without any effect on the reads: Local can be deployed before the assistant, and the
      #   actions cut without a deployment. It is checked after the API key and the token, so a
      #   request without them is refused as usual.
      # - `run_action` runs the action once per `Idempotency-Key` (Assistant::ActionRunner).
      class ActionsController < BaseController
        before_action :ensure_actions_enabled!

        private

        def ensure_actions_enabled!
          return if ActiveModel::Type::Boolean.new.cast(ENV['ASSISTANT_ACTIONS_ENABLED'])

          render_error(code: 'ACTIONS_DISABLED', message: 'The actions of the assistant are disabled.', status: :service_unavailable)
        end

        # `payload` is everything that defines the request (ids and texts): it is only hashed,
        # to refuse a key reused for another request. The block returns the Outcome.
        def run_action action_type, payload = {}, &block
          runner = ::Assistant::ActionRunner.new(
            user: assistant_user, key: request.headers['Idempotency-Key'],
            action_type: action_type, payload: payload
          )
          response = runner.call(&block)

          @assistant_action_log = {
            assistant_action: action_type, assistant_result: response.result, assistant_replayed: response.replayed
          }
          headers['Idempotent-Replayed'] = 'true' if response.replayed
          render json: response.body, status: response.status
        end

        # Type, result and replay of the action in the logs (Lograge), never its content.
        def append_info_to_payload(payload)
          super
          payload.merge!(@assistant_action_log) if @assistant_action_log
        end
      end
    end
  end
end
