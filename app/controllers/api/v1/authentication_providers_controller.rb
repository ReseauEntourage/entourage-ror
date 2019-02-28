module Api
  module V1
    class AuthenticationProvidersController < Api::V1::BaseController
      skip_before_filter :authenticate_user!

      def create
        if authent_params[:source] == "facebook"
          authenticator = Facebook::FacebookAuthenticator.new(token: authent_params[:token])
        elsif authent_params[:source] == "twitter"
          authenticator = Twitter::TwitterAuthenticator.new(token: authent_params[:token], token_secret: authent_params[:token_secret])
        end
        authenticator.authenticate do |on|
          on.login_success do |user|
            render json: user, status: 200, serializer: ::V1::UserSerializer, scope: { user: user }
          end

          on.save_user_error do |user|
            return render json: {message: user.errors.full_messages}, status: 401
          end

          on.invalid_token do |token|
            return render json: {message: "Invalid token : #{token}"}, status: 401
          end

          on.provider_error do |error_message|
            return render json: {message: "Provider error : #{error_message}"}, status: 401
          end
        end
      end

      private
      def authent_params
        params.require(:authentification_provider).permit(:source, :token)
      end
    end
  end
end
