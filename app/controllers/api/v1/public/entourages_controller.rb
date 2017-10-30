module Api
  module V1
    module Public
      class EntouragesController < Api::V1::Public::BaseController
        before_action :set_entourage, only: [:show]

        def show
          if @entourage
            render json: @entourage, serializer: ::V1::Public::EntourageSerializer
          else
            render json: { message: "Could not found Entourage" }, status: 404
          end
        end

        def index
          @entourages = Entourage.visible

          if params[:preset] == "atd-paris"
            @entourages = @entourages
              .where(status: :open)
              .where("title || description ~* '(biblioth[eè]que de rue)|(atd)|(université)|(stop.p)'")
              .within_bounding_box(
                Geocoder::Calculations.bounding_box(
                  ['48.856667', '2.342222'],
                  10, units: :km
                )
              )
          else
            @entourages = []
          end

          render json: @entourages, each_serializer: ::V1::Public::EntourageSerializer, scope: :map
        end

        private

        def set_entourage
          key =
            if params[:uuid].is_a?(String) && params[:uuid].length == 36
              :uuid
            else
              :uuid_v2
            end

          @entourage = Entourage.visible.find_by(key => params[:uuid])
        end
      end
    end
  end
end
