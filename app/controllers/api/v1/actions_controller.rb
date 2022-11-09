module Api
  module V1
    class ActionsController < Api::V1::BaseController
      def index
        render json: ActionServices::Finder.new(current_user, index_params).find_all.page(page).per(per), root: :actions, each_serializer: ::V1::ActionSerializer, scope: {
          user: current_user
        }
      end

      private

      def index_params
        params.permit(:latitude, :longitude, :travel_distance, :page, :per)
      end

      def page
        params[:page] || 1
      end

      def per
        params[:per] || 25
      end
    end
  end
end