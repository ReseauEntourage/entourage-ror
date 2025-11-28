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

        return render json: {
          message: :no_places
        }, status: :bad_request unless body.has_key?('places')

        render json: { message: :ok, count: body['places'].count }, status: :ok
      end

      # GET https://api.soliguide.fr/place/:lieu_id
      def soliguide
        response = PoiServices::SoliguideShow.uptime

        validate_response! response

        body = JSON.parse(response.body)

        return render json: {
          message: :no_place
        }, status: :bad_request unless body.has_key?('lieu_id')

        render json: { message: :ok, lieu_id: body['lieu_id'] }, status: :ok
      end

      private

      def authenticate_super_admin!
        render json: {
          message: :unauthorized
        }, status: :unauthorized unless current_user && current_user.super_admin?
      end

      def validate_response! response
        raise ActionController::InvalidAuthenticityToken, :bad_token if ['401'].include?(response.code.to_s)
        # raise ActionController::InvalidAuthenticityToken, :bad_token if ['403'].include?(response.code.to_s)
        raise ActionController::BadRequest, :unexcepted_status unless ['200', '201'].include?(response.code.to_s)
      end

      def rescue_parse_error
        render json: { message: :not_parsable }, status: :bad_request
      end

      def rescue_unauthorized error
        render json: { message: error.message }, status: :unauthorized
      end

      def rescue_bad_request error
        render json: { message: error.message }, status: :bad_request
      end
    end
  end
end
