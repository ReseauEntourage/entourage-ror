module Api
  module V1
    class UserApplicationsController < Api::V1::BaseController
      def update
        user_application = @current_user.user_applications.where(device_os: user_application_params["device_os"],
                                                                 version: user_application_params["version"]).first_or_initialize
        user_application.tap do |user_application|
          user_application.push_token = user_application_params["push_token"]
          user_application.device_family = api_request.key_infos.try(:[], :device_family)
        end
        if user_application.save
          head :no_content
        else
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
