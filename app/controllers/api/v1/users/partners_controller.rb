module Api
  module V1
    module Users
      class PartnersController < Api::V1::BaseController
        before_action :set_user

        def index
          render json: {
              
          }, status: 200, each_serializer: ::V1::TourSerializer, scope: {user: current_user}
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

      end
    end
  end
end