module Api
  module V1
    class SlackEventsController < Api::V1::BaseController
      skip_before_action :authenticate_user!
      skip_before_action :verify_authenticity_token

      before_action :verify_slack_request!

      def create
        if params[:type] == 'url_verification'
          return render json: { challenge: params[:challenge] }
        end

        event = params[:event]

        if event && event[:type] == 'app_mention'
          SlackQuestionJob.perform_later(
            channel: event[:channel],
            ts: event[:ts],
            text: event[:text],
            user: event[:user]
          )
        end

        head :ok
      end

      private

      def verify_slack_request!
        return if SlackServices::JulesRequestVerification.new(request).verify!

        head :unauthorized
      end
    end
  end
end
