require 'api/v1/api_error'

module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      before_action :community_warning
      before_action :validate_request!, only: [:check]
      before_action :ensure_community!, except: [:options]
      before_action :authenticate_user!, except: [:check, :options]
      before_action :set_raven_context

      after_action :set_completed_user_recommandations, only: [:index, :show, :create], if: -> { current_user.present? }

      rescue_from ApiRequest::Unauthorised do |e|
        Rails.logger.error e
        render json: {message: 'Missing API Key or invalid key'}, status: 426
      end

      rescue_from ApiError do |e|
        Rails.logger.error e
        render json: e.as_json, status: e.code
      end

      rescue_from ActionController::ParameterMissing do |e|
        Rails.logger.error e
        render_error(code: "PARAMETER_MISSING", message: e.message, status: :bad_request)
      end

      def allow_cors
        headers["Access-Control-Allow-Origin"] = "*"
        headers["Access-Control-Allow-Methods"] = %w{GET POST PUT PATCH DELETE}.join(",")
        headers["Access-Control-Allow-Headers"] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token X-API-KEY}.join(",")
      end

      def options
        head(:ok)
      end

      def current_user
        @current_user ||= community.users.find_by_token params[:token]
      end

      def current_anonymous_user
        if @anonymous_token != nil
          return @current_anonymous_user
        end
        @anonymous_token = AnonymousUserService.token?(params[:token], community: community)
        return unless @anonymous_token
        @current_anonymous_user = AnonymousUserService.find_user_by_token(params[:token], community: community)
      end

      def authenticate_user!
        if current_user && !current_user.deleted && !current_user.blocked?
          track_session

          unless current_user.last_sign_in_at.try(:today?)
            first_session = current_user.last_sign_in_at.nil?
            reactivated = !first_session && current_user.last_sign_in_at <= 2.months.ago
            current_user.update_column(:last_sign_in_at, Time.zone.now)
            mixpanel.track("Opened App", {
              "First Session" => first_session
            })
            mixpanel.track("Reactivated", { "Threshold (Months)" => 2 }) if reactivated
            mixpanel.set_once("First Seen" => current_user.last_sign_in_at)
            # TODO(partner)
            # "Partner Badge" => current_user.default_partner.try(:name)
            mixpanel.set(
              '$first_name' => current_user.first_name,
              '$last_name' => current_user.last_name,
              '$email' => current_user.email,
              'user_id' => UserServices::EncodedId.encode(current_user.id)
            )
          end
        else
          render json: {message: 'unauthorized'}, status: :unauthorized
        end
      end

      def authenticate_user_or_anonymous!
        if current_anonymous_user
          # ok
        else
          authenticate_user!
        end
      end

      def current_user_or_anonymous
        current_anonymous_user || current_user
      end

      def self.allow_anonymous_access only:
        skip_before_action :authenticate_user!, only: only
        before_action :authenticate_user_or_anonymous!, only: only
      end

      def validate_request!
        api_request.validate!
      end

      def render_error(code:, message:, status:)
        render json: {"error":{"code":code, "message":message}}, status: status
      end

      #curl -H "X-API-KEY: api_debug" "http://api.entourage.social/api/v1/check.json"
      def check
        render json: { status: :ok }
      end

      def ping
        render json: { status: :ok }
      end

      def ping_db
        render json: { status: :ok, count: User.count }
      end

      def api_request
        @api_request ||= ApiRequest.new(params: params, headers: headers, env: request.env)
      end

      def community
        @community ||= begin
          key_infos = api_request.key_infos
          if key_infos
            Community.new(api_request.key_infos[:community])
          else
            $server_community
          end
        end
      end

      def api_request_platform
        @api_request_platform ||= api_request.key_infos.try(:[], :device)
      end

      def mixpanel
        @mixpanel ||= MixpanelService.new(
          distinct_id: current_user.try(:id),
          default_properties: {
            'Platform' => api_request_platform,
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
        payload[:ip] = request.remote_ip
        payload[:request_id] = request.uuid
        payload[:platform] = api_request.key_infos.try(:[], :device)
        payload[:version] = api_request.key_infos.try(:[], :version)
        payload[:user] = current_user_or_anonymous&.uuid
        payload[:api_key] = api_request.api_key
      end

      private

      def track_session
        SessionHistory.track user_id: current_user.id, platform: api_request_platform
      rescue => e
        Raven.capture_exception(e)
      end

      def set_raven_context
        Raven.user_context(id: current_user.try(:id))
        Raven.extra_context(
          params: params.to_unsafe_h,
          url: request.url,
          platform: api_request_platform,
          app_version: api_request.key_infos.try(:[], :version),
        )
      end

      def ensure_community!
        if api_request.key_infos.blank? && $server_community == :entourage
          logger.warn "type=community.warning code=no_api_key controller=#{controller_path} action=#{action_name}"
          return
        end

        if api_request.key_infos.blank? || $server_community != api_request.key_infos[:community]
          return render json: { message: 'Unauthorized API key' }, status: :unauthorized
        end
      end

      def community_warning
        return if $server_community == :entourage
        logger.warn "type=community.warning code=community_support_missing controller=#{controller_path} action=#{action_name}"
      end

      def set_completed_user_recommandations
        return unless current_user
        return unless [200, 201].include?(response.status)

        RecommandationServices::Completor.new(
          user: current_user,
          controller_name: controller_name,
          action_name: action_name,
          params: params
        ).run
      end
    end
  end
end
