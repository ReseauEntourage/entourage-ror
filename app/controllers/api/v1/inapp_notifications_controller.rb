module Api
  module V1
    class InappNotificationsController < Api::V1::BaseController
      before_action :set_inapp_notification, only: [:destroy]
      after_action :set_inapp_notications_displayed_at, only: [:index]

      def index
        render json: current_user.inapp_notifications.page(page).per(per), each_serializer: ::V1::InappNotificationSerializer
      end

      def count
        render json: { count: current_user.inapp_notifications.not_displayed.count }
      end

      def destroy
        return render json: { message: 'unauthorized' }, status: :unauthorized if @inapp_notification.user != current_user

        if @inapp_notification.update_attribute(:completed_at, Time.zone.now)
          render json: @inapp_notification, status: 200, serializer: ::V1::InappNotificationSerializer
        else
          render json: {
            message: 'Could not update inapp_notification', reasons: @inapp_notification.errors.full_messages
          }, status: 400
        end
      end

      private

      def set_inapp_notification
        @inapp_notification = InappNotification.find(params[:id])
      end

      def page
        params[:page] || 1
      end

      def per
        params[:per] || 25
      end

      private

      def set_inapp_notications_displayed_at
        current_user.inapp_notifications.not_displayed.update_all(displayed_at: Time.zone.now)
      end
    end
  end
end
