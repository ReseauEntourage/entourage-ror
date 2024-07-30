module Api
  module V1
    module Users
      class NeighborhoodsController < Api::V1::BaseController
        before_action :set_user

        def index
          render json: NeighborhoodServices::Finder.new(@user, index_params).find_all_participations
            .includes(:translation, :image_resize_actions, :user)
            .page(page)
            .per(per), root: :neighborhoods, each_serializer: ::V1::Neighborhoods::MemberListSerializer, scope: { user: @user }
        end

        private

        def set_user
          @user = if params[:user_id] == "me"
            current_user
          else
            User.find(params[:user_id])
          end
        end

        def page
          params[:page] || 1
        end

        def per
          params[:per] || 50
        end

        def index_params
          params.permit(:q, :interest_list, interests: [])
        end
      end
    end
  end
end
