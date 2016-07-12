module Api
  module V0
    module Users
      class ToursController < Api::V0::BaseController
        before_action :set_user

        def index
          page = params[:page] || 1
          per = [(params[:per].try(:to_i) || 25), 25].min
          tours = @user.tours.order(updated_at: :desc).page(page).per(per)
          # @todo: John hot fix
          tours = @user.tours.order(updated_at: :desc).page(page).per(10) if @user.id == 240
          render json: tours, status: 200, each_serializer: ::V0::TourSerializer
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end
      end
    end
  end
end
