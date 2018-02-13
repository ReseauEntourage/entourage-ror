module Api
  module V1
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
        if current_user && !current_user.deleted
          unless current_user.last_sign_in_at.try(:today?)
            first_session = current_user.last_sign_in_at.nil?
            reactivated = !first_session && current_user.last_sign_in_at <= 3.months.ago
            current_user.update(last_sign_in_at: DateTime.now)
            mixpanel.track("Opened App", {
              "First Session" => first_session,
              "Feature / Feed" => FeatureSwitch.new(current_user).variant(:feed)
            })
            mixpanel.track("Reactivated", { "Threshold (Months)" => 3 }) if reactivated
            mixpanel.set_once("First Seen" => current_user.last_sign_in_at)
            mixpanel.set(
              '$first_name' => current_user.first_name,
              '$last_name' => current_user.last_name,
              '$email' => current_user.email,
              'user_id' => UserServices::EncodedId.encode(current_user.id),
              "Partner Badge" => current_user.default_partner.try(:name)
            )
          end
        else
          render json: {message: 'unauthorized'}, status: :unauthorized
        end
      end

      def validate_request!
        begin
          api_request.validate!
        rescue UnauthorisedApiKeyError => e
          Rails.logger.error e
          return render json: {message: 'Missing API Key or invalid key'}, status: 426
        end
      end

      def render_error(code:, message:, status:)
        render json: {"error":{"code":code, "message":message}}, status: status
      end

      #curl -H "X-API-KEY: api_debug" "http://api.entourage.social/api/v1/check.json"
      def check
        render json: {status: :ok}
      end

      def ping
        render json: {status: :ok}
      end

      def api_request
        @api_request ||= ApiRequest.new(params: params, headers: headers, env: request.env)
      end

      def mixpanel
        @mixpanel ||= MixpanelService.new(
          distinct_id: current_user.try(:id),
          default_properties: {
            'Platform' => api_request.key_infos.try(:[], :device),
            '$app_version_string' => api_request.key_infos.try(:[], :version),
            'ip' => request.remote_ip
          },
          event_prefix: "Backend"
        )
      end

      def per
        [params[:per].try(:to_i) || 10, 25].min
      end

      # For logging API_KEY with lograge
      def append_info_to_payload(payload)
        super
        payload[:api_key] = api_request.api_key
      end
    end
  end
end
