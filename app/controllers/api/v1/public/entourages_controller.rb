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

        private

        def set_entourage
          @entourage = Entourage.visible.find_by(uuid: params[:uuid])
        end
      end
    end
  end
end
