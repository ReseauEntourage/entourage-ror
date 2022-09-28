module Api
  module V1
    class WebviewsController < Api::V1::BaseController
      def show
        render json: { url: params[:url] }
      end
    end
  end
end
