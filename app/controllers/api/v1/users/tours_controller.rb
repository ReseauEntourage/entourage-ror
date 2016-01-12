module Api
  module V1
    module Users
      class ToursController < Api::V1::BaseController
        before_action :set_user

        def index
          page = params[:page] || 1
          per = [(params[:per].try(:to_i) || 25), 25].min
          tours = @user.tours.order(updated_at: :desc).page(page).per(per)
          render json: tours, status: 200
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end
      end
    end
  end
end

