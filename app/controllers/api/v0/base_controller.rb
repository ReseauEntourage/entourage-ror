module Api
  module V0
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      before_filter :validate_request!
      before_filter :authenticate_user!, except: [:ping]

      def current_user
        @current_user ||= User.find_by_token params[:token]
      end

      def authenticate_user!
        if current_user
          UserServices::LoginHistoryService.new(user: current_user).record_login!
        else
          render 'unauthorized', status: :unauthorized
        end
      end

      def validate_request!
        begin
          ApiRequestValidator.new(params: params, headers: headers, env: request.env).validate!
        rescue UnauthorisedApiKeyError => e
          Rails.logger.error e
          return render json: {message: 'Missing API Key or invalid key'}, status: 426
        end
      end

      def ping
        render json: {status: :ok}
      end
    end
  end
end
