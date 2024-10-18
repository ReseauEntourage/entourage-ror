module Api
  module V1
    module Users
      class NeighborhoodsController < Api::V1::BaseController
        before_action :set_user
        before_action :set_default_neighborhood, only: [:default]

        def index
          render json: NeighborhoodServices::Finder.new(@user, index_params).find_all_participations
            .select("neighborhoods.*, join_requests.unread_messages_count")
            .includes(:translation, :image_resize_actions, :future_outings)
            .order(national: :desc, name: :asc)
            .page(page)
            .per(per), root: :neighborhoods, each_serializer: ::V1::Neighborhoods::MemberListSerializer, scope: { user: @user }
        end

        def default
          return head :not_found unless @user.default_neighborhood

          render json: @user.default_neighborhood, serializer: ::V1::NeighborhoodHomeSerializer, scope: { user: @user }
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

        def set_default_neighborhood
          return unless current_user == @user

          NeighborhoodServices::Joiner.new(current_user).join_default_neighborhood!
        end
      end
    end
  end
end
