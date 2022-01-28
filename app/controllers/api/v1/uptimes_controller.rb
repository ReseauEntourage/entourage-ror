module Api
  module V1
    class UptimesController < Api::V1::BaseController
      skip_before_action :authenticate_user!
      before_action :authenticate_super_admin!

      # POST https://api.soliguide.fr/new-search
      def soliguides
        response = PoiServices::SoliguideIndex.uptime

        return render json: {
          message: :bad_token
        }, status: :unauthorized if ["401", "403"].include?(response.code.to_s)

        return render json: {
          message: :unexcepted_status
        }, status: :bad_request unless ["200", "201"].include?(response.code.to_s)

        body = JSON.parse(response.read_body)

        return render json: {
          message: :no_places
        }, status: :bad_request unless body.has_key?('places')

        render json: { message: :ok, count: body['places'].count }, status: :ok
      rescue JSON::ParserError => e
        render json: { message: :not_parsable }, status: :bad_request
      end

      # GET https://api.soliguide.fr/place/:lieu_id
      def soliguide
        response = PoiServices::SoliguideShow.uptime

        return render json: {
          message: :bad_token
        }, status: :unauthorized if ["401", "403"].include?(response.code.to_s)

        return render json: {
          message: :unexcepted_status
        }, status: :bad_request unless ["200", "201"].include?(response.code.to_s)

        body = JSON.parse(response.body)

        return render json: {
          message: :no_place
        }, status: :bad_request unless body.has_key?('lieu_id')

        render json: { message: :ok, lieu_id: body['lieu_id'] }, status: :ok
      rescue JSON::ParserError => e
        render json: { message: :not_parsable }, status: :bad_request
      end

      private

      def authenticate_super_admin!
        render json: {
          message: :unauthorized
        }, status: :unauthorized unless current_user && current_user.super_admin?
      end
    end
  end
end
