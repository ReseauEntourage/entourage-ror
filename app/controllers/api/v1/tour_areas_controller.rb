module Api
  module V1
    class TourAreasController < Api::V1::BaseController
      def index
        render json: TourArea.all, each_serializer: ::V1::TourAreaSerializer
      end

      def show
        render json: TourArea.find(params[:id]), status: 200, serializer: ::V1::TourAreaSerializer
      end

      def tour_request
        render json: {
          message: 'Could not find tour area',
          code: :tour_area_not_found
        }, status: 400 and return unless TourArea.find_by_id(params[:id])

        AdminMailer.tour_request(
          id: params[:id],
          user_id: current_user.id,
          params: request_params
        ).deliver_later

        render json: { message: 'Un email a été envoyé avec votre demande au modérateur de la zone.' }
      end

      private

      def request_params
        params.require(:request).permit(:message)
      end
    end
  end
end
