module Api
  module V1
    module Users
      class NeighborhoodsController < Api::V1::BaseController
        before_action :set_user

        def index
          render json: NeighborhoodServices::Finder.search_participations(user: @user, params: index_params)
            .includes(:translation, :members, :image_resize_actions)
            .page(page)
            .per(per), root: :neighborhoods, each_serializer: ::V1::NeighborhoodSerializer, scope: { user: @user }
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def page
          params[:page] || 1
        end

        def per
          params[:per] || 50
        end

        def index_params
          params.permit(:q, interests: [])
        end
      end
    end
  end
end
