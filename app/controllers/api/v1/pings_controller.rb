module Api
  module V1
    class PingsController < Api::V1::BaseController
      skip_before_action :authenticate_user!
      skip_before_action :ensure_community!
      skip_before_action :validate_request!

      def dispatch_websocket
        message = params[:message] || "Ping at #{Time.now}"
        ActionCable.server.broadcast("ping_channel", { message: message })
        render json: { status: "Message broadcasted", message: message }
      end
    end
  end
end
