module Api
  module V1
    class UserApplicationsController < Api::V1::BaseController
      #curl -X PUT -H 'API_KEY:2b8259ac4aad2cfd0b46be77' -d '{ "application": {"device_family": "ANDROID", "device_os": "android 6.0.1", "push_token": "fSxmlgKhWuY:APA91bEgeYtJsRRwZQAJxaeoelG42N9NuDH8Im3Mor8F1_TplGhRnXUrI6MhZRppXOwyuHKjWVWTn1Cu0zCdO_U8DjR2VQFE0rDx4d4PLQ123Tixw-tfxLi2gB6QraZBCPE1Q9F2lijy", "version": "1.2.608" }}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/applications.json?token=0cb4507e970462ca0b11320131e96610"
      def update
        if user_application_params[:push_token].in?(['0', ''])
          # we don't delete tokens anymore
          return head :no_content
        end

        user_application = UserApplication.find_or_initialize_by(push_token: user_application_params[:push_token])

        device_family =
          case user_application_params[:push_token].length
          when 152 then UserApplication::ANDROID
          when  64 then UserApplication::IOS
          else api_request.key_infos.try(:[], :device_family)
          end

        user_application.attributes = {
          version:       user_application_params[:version],
          device_os:     user_application_params[:device_os],
          device_family: device_family,
          user_id:       current_user.id,
        }

        begin
          user_application.skip_uniqueness_validation_of_push_token!
          user_application.save!
          head :no_content
        rescue => e
          Raven.capture_exception(e)
          render json: {message: 'Could not create user_application', reasons: user_application.errors.full_messages}, status: :bad_request
        end
      end

      private

      def user_application_params
        params.require(:application).permit(:push_token, :device_os, :version)
      end
    end
  end
end
