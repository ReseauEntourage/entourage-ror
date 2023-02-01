module Api
  module V1
    module Users
      class NeighborhoodsController < Api::V1::BaseController
        before_action :set_user

        def index
          page = params[:page] || 1
          per = 200

          neighborhoods = Neighborhood.joins(:join_requests)
            .where(join_requests: { user: @user, status: JoinRequest::ACCEPTED_STATUS })
            .order(created_at: :desc)
            .page(page)
            .per(per)

          render json: neighborhoods, status: 200, each_serializer: ::V1::NeighborhoodSerializer, scope: { user: current_user }
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end
      end
    end
  end
end
