module Api
  module V1
    module Users
      class OutingsController < Api::V1::BaseController
        before_action :set_user

        def index
          outings = OutingsServices::Finder.new(@user, index_params)
            .find_all_participations
            .future_or_past_today
            .default_order
            .page(page)
            .per(per)

          ::Preloaders::Outing.preload_for_serializer(outings, user: @user)

          render json: outings, root: :outings, each_serializer: ::V1::OutingSerializer, scope: {
            user: @user
          }
        end

        def past
          outings = OutingsServices::Finder.new(@user, index_params)
            .find_all_participations
            .past
            .reversed_order
            .page(page)
            .per(per)

          ::Preloaders::Outing.preload_for_serializer(outings, user: @user)

          render json: outings, root: :outings, each_serializer: ::V1::OutingSerializer, scope: {
            user: @user
          }
        end

        private

        def set_user
          @user = if params[:user_id] == 'me'
            current_user
          else
            User.find_by_id_or_uuid!(params[:user_id])
          end
        end

        def page
          params[:page] || 1
        end

        def per
          params[:per] || 50
        end

        def index_params
          params.permit(:q, :latitude, :longitude, :distance, :interest_list, interests: [])
        end
      end
    end
  end
end
