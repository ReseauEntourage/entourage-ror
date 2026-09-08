module Api
  module V1
    class UptimesController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:soliguides, :soliguide]
      before_action :authenticate_super_admin!, only: [:soliguides, :soliguide]

      rescue_from JSON::ParserError, with: :rescue_parse_error
      rescue_from ActionController::InvalidAuthenticityToken, with: :rescue_unauthorized
      rescue_from ActionController::BadRequest, with: :rescue_bad_request

      # POST https://api.soliguide.fr/new-search
      def soliguides
        response = PoiServices::SoliguideIndex.uptime

        validate_response! response

        body = JSON.parse(response.read_body)

        return render_error(status: :bad_request, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: {
          message: :no_places
        }) unless body.has_key?('places')

        render json: { message: :ok, count: body['places'].count }, status: :ok
      end

      # GET https://api.soliguide.fr/place/:lieu_id
      def soliguide
        response = PoiServices::SoliguideShow.uptime

        validate_response! response

        body = JSON.parse(response.body)

        return render_error(status: :bad_request, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: {
          message: :no_place
        }) unless body.has_key?('lieu_id')

        render json: { message: :ok, lieu_id: body['lieu_id'] }, status: :ok
      end

      private

      # Internal ops/monitoring endpoint, not called by the mobile apps - kept at 401.
      def authenticate_super_admin!
        render_error(status: :unauthorized, code: Api::V1::ErrorCodes::UNAUTHORIZED, legacy: {
          message: :unauthorized
        }) unless current_user && current_user.super_admin?
      end

      def validate_response! response
        raise ActionController::InvalidAuthenticityToken, :bad_token if ['401', '403'].include?(response.code.to_s)
        raise ActionController::BadRequest, :unexcepted_status unless ['200', '201'].include?(response.code.to_s)
      end

      def rescue_parse_error
        render_error(status: :bad_request, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: { message: :not_parsable })
      end

      def rescue_unauthorized error
        render_error(status: :unauthorized, code: Api::V1::ErrorCodes::UNAUTHORIZED, legacy: { message: error.message })
      end

      def rescue_bad_request error
        render_error(status: :bad_request, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: { message: error.message })
      end
    end
  end
end
