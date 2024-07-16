module Api
  module V1
    module Users
      class OutingsController < Api::V1::BaseController
        before_action :set_user

        def index
          render json: OutingsServices::Finder.new(@user, index_params)
            .find_all_participations
            .future_or_recently_past
            .default_order
            .includes(:translation, :user, :members, :confirmed_members, :interests, :recurrence)
            .page(page)
            .per(per), root: :outings, each_serializer: ::V1::OutingSerializer, scope: {
              user: @user
            }
        end

        def past
          render json: OutingsServices::Finder.new(@user, index_params)
            .find_all_participations
            .past
            .reversed_order
            .includes(:translation, :user, :members, :confirmed_members, :interests, :recurrence)
            .page(page)
            .per(per), root: :outings, each_serializer: ::V1::OutingSerializer, scope: {
              user: @user
            }
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
          params.permit(:q, :latitude, :longitude, :travel_distance, :interest_list, interests: [])
        end
      end
    end
  end
end
