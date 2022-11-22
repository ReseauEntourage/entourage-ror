module Api
  module V1
    class NotificationPermissionsController < Api::V1::BaseController
      def index
        render json: current_user.notification_permission, root: :notification_permissions, serializer: ::V1::NotificationPermissionSerializer
      end

      def create
        @notification_permission = NotificationPermission.find_or_initialize_by(user_id: current_user.id)
        @notification_permission.assign_attributes(notification_permission_params)

        if @notification_permission.save
          render json: @notification_permission, root: :notification_permissions, status: 201, serializer: ::V1::NotificationPermissionSerializer
        else
          render json: { message: "Could not create notification_permission", reasons: @notification_permission.errors.full_messages }, status: 400
        end
      end

      private

      def notification_permission_params
        params.require(:notification_permissions).permit(:neighborhood, :outing, :private_chat_message)
      end
    end
  end
end
