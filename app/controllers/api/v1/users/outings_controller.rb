module Api
  module V1
    module Users
      class OutingsController < Api::V1::BaseController
        before_action :set_user

        def index
          page = params[:page] || 1
          per = [(params[:per].try(:to_i) || 25), 25].min

          outings = Outing.future_or_recently_past
            .joins(:join_requests)
            .where(join_requests: { user: @user, status: JoinRequest::ACCEPTED_STATUS })
            .default_order
            .page(page)
            .per(per)

          render json: outings, status: 200, each_serializer: ::V1::OutingSerializer, scope: { user: current_user }
        end

        def past
          page = params[:page] || 1
          per = [(params[:per].try(:to_i) || 25), 25].min

          outings = Outing.past
            .joins(:join_requests)
            .where(join_requests: { user: @user, status: JoinRequest::ACCEPTED_STATUS })
            .reversed_order
            .page(page)
            .per(per)

          render json: outings, status: 200, each_serializer: ::V1::OutingSerializer, scope: { user: current_user }
        end

        private

        def set_user
          @user = if params[:user_id] == "me"
            current_user
          else
            User.find(params[:user_id])
          end
        end
      end
    end
  end
end
