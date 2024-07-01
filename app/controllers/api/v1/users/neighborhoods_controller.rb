module Api
  module V1
    module Users
      class NeighborhoodsController < Api::V1::BaseController
        before_action :set_user

        def index
          neighborhoods = Neighborhood.joins(:join_requests)
            .where(join_requests: { user: @user, status: JoinRequest::ACCEPTED_STATUS })
            .order(national: :desc, name: :asc)
            .page(page)
            .per(per)

          render json: neighborhoods, status: 200, each_serializer: ::V1::NeighborhoodSerializer, scope: { user: current_user }
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def page
          params[:page] || 1
        end

        def per
          params[:per] || 200
        end
      end
    end
  end
end
