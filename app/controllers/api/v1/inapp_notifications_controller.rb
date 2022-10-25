module Api
  module V1
    class InappNotificationsController < Api::V1::BaseController
      def index
        render json: current_user.inapp_notifications.active, each_serializer: ::V1::InappNotificationSerializer
      end
    end
  end
end
