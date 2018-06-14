module Api
  module V1
    class UserApplicationsController < Api::V1::BaseController
      #curl -X PUT -H 'API_KEY:2b8259ac4aad2cfd0b46be77' -d '{ "application": {"device_family": "ANDROID", "device_os": "android 6.0.1", "push_token": "fSxmlgKhWuY:APA91bEgeYtJsRRwZQAJxaeoelG42N9NuDH8Im3Mor8F1_TplGhRnXUrI6MhZRppXOwyuHKjWVWTn1Cu0zCdO_U8DjR2VQFE0rDx4d4PLQ123Tixw-tfxLi2gB6QraZBCPE1Q9F2lijy", "version": "1.2.608" }}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/applications.json?token=0cb4507e970462ca0b11320131e96610"
      def update
        ActiveRecord::Base.transaction do
          UserApplication.where(push_token: user_application_params["push_token"]).delete_all
          if user_application_params["push_token"] == "0" || user_application_params["push_token"] == ""
            @current_user.user_applications.where(device_os: user_application_params["device_os"], version: user_application_params["version"]).destroy_all
            head :no_content
          else
            user_application = @current_user.user_applications.where(device_os: user_application_params["device_os"],
                                                                     version: user_application_params["version"]).first_or_initialize
            user_application.tap do |user_application|
              user_application.push_token = user_application_params["push_token"]
              user_application.device_family = api_request.key_infos.try(:[], :device_family)
              # hot fix to be sure that we have the right device family in case API keys are not the right ones
              user_application.device_family = UserApplication::ANDROID if user_application.push_token.length == 152
              user_application.device_family = UserApplication::IOS if user_application.push_token.length == 64
            end

            if user_application.save!
              head :no_content
            else
              render json: {message: 'Could not create user_application', reasons: user_application.errors.full_messages}, status: :bad_request
            end
          end
        end
      end

      private

      def user_application_params
        params.require(:application).permit(:push_token, :device_os, :version)
      end
    end
  end
end
