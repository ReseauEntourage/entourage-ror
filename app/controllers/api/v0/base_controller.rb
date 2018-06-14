module Api
  module V0
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      before_filter :allow_cors
      before_filter :validate_request!, only: [:check]
      before_filter :authenticate_user!, except: [:check]

      def allow_cors
        headers["Access-Control-Allow-Origin"] = "*"
        headers["Access-Control-Allow-Methods"] = %w{GET POST PUT DELETE}.join(",")
        headers["Access-Control-Allow-Headers"] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token X-API-Auth-Token}.join(",")
      end

      def options
        head(:ok)
      end

      def current_user
        @current_user ||= User.find_by_token params[:token]
      end

      def authenticate_user!
        if current_user
          #UserServices::LoginHistoryService.new(user: current_user).record_login!
        else
          render json: {message: 'unauthorized'}, status: :unauthorized
        end
      end

      def validate_request!
        begin
          ApiRequest.new(params: params, headers: headers, env: request.env).validate!
        rescue ApiRequest::Unauthorised => e
          Rails.logger.error e
          return render json: {message: 'Missing API Key or invalid key'}, status: 426
        end
      end

      def check
        render json: {status: :ok}
      end

      def api_request
        @api_request ||= ApiRequest.new(params: params, headers: headers, env: request.env)
      end

      # For logging API_KEY with lograge
      def append_info_to_payload(payload)
        super
        payload[:api_key] = api_request.api_key
      end
    end
  end
end
