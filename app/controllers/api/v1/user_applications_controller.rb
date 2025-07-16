module Api
  module V1
    class UserApplicationsController < Api::V1::BaseController
      allow_anonymous_access only: [:update, :destroy]

      #curl -X PUT -H 'API_KEY:2b8259ac4aad2cfd0b46be77' -d '{ "application": {"device_family": "ANDROID", "device_os": "android 6.0.1", "push_token": "fSxmlgKhWuY:APA91bEgeYtJsRRwZQAJxaeoelG42N9NuDH8Im3Mor8F1_TplGhRnXUrI6MhZRppXOwyuHKjWVWTn1Cu0zCdO_U8DjR2VQFE0rDx4d4PLQ123Tixw-tfxLi2gB6QraZBCPE1Q9F2lijy", "version": "1.2.608" }}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/applications.json?token=0cb4507e970462ca0b11320131e96610"
      def update
        return head :no_content if current_user_or_anonymous.anonymous?
        if user_application_params[:push_token].in?(['0', ''])
          # we don't delete tokens anymore
          return head :no_content
        end

        user_application = UserApplication.find_or_initialize_by(push_token: user_application_params[:push_token])

        device_family_fallback =
          case user_application_params[:push_token].length
          when 152 then UserApplication::ANDROID
          when 174 then UserApplication::ANDROID
          when  64 then UserApplication::IOS
          end

        device_family = api_request.key_infos.try(:[], :device_family) || device_family_fallback

        user_application.attributes = {
          version:       user_application_params[:version],
          device_os:     user_application_params[:device_os],
          device_family: device_family,
          notifications_permissions: user_application_params[:notifications_permissions],
          user_id:       current_user.id,
        }

        SessionHistory.track_notifications_permissions(
          user_id: current_user.id,
          platform: api_request_platform,
          notifications_permissions: user_application_params[:notifications_permissions]
        )

        begin
          user_application.skip_uniqueness_validation_of_push_token!
          user_application.save!
          head :no_content
        rescue ActiveRecord::RecordNotUnique
          head :no_content
        rescue => e
          Sentry.capture_exception(e)
          render json: {message: 'Could not create user_application', reasons: user_application.errors.full_messages}, status: :bad_request
        end
      end

      #curl -X DELETE -H 'API_KEY:2b8259ac4aad2cfd0b46be77' -d '{ "application": {"device_family": "ANDROID", "device_os": "android 6.0.1", "push_token": "fSxmlgKhWuY:APA91bEgeYtJsRRwZQAJxaeoelG42N9NuDH8Im3Mor8F1_TplGhRnXUrI6MhZRppXOwyuHKjWVWTn1Cu0zCdO_U8DjR2VQFE0rDx4d4PLQ123Tixw-tfxLi2gB6QraZBCPE1Q9F2lijy", "version": "1.2.608" }}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/applications.json?token=0cb4507e970462ca0b11320131e96610"
      def destroy
        UserApplication.where(push_token: user_application_params["push_token"]).destroy_all

        head :no_content
      end

      private

      def user_application_params
        params.require(:application).permit(:push_token, :device_os, :version, :notifications_permissions)
      end
    end
  end
end
