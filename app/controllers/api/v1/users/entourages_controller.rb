module Api
  module V1
    module Users
      class EntouragesController < Api::V1::BaseController
        before_action :set_user

        def index
          page = params[:page] || 1
          per = [(params[:per].try(:to_i) || 25), 25].min
          entourages = Entourage
                           .joins(:join_requests)
                           .where(join_requests: {user: @user, status: JoinRequest::ACCEPTED_STATUS})
                           .order(updated_at: :desc)
                           .page(page)
                           .per(per)
          if position_params?
            entourages = entourages.around(params[:latitude], params[:longitude], params[:distance])
          end
          entourages = entourages.where(status: Tour.statuses[params[:status]]) if params[:status].present?
          render json: entourages, status: 200, each_serializer: ::V1::EntourageSerializer
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def position_params?
          params[:distance] &&
              params[:latitude] &&
              params[:longitude]
        end
      end
    end
  end
end