module Api
  module V1
    module Neighborhoods
      class ImagesController < Api::V1::BaseController
        def index
          render json: NeighborhoodImage.order(id: :desc), each_serializer: ::V1::NeighborhoodImageSerializer
        end
      end
    end
  end
end
