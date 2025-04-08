module Api
  module V1
    class UserSmalltalksController < Api::V1::BaseController
      before_action :set_user_smalltalk, only: [:show, :update, :destroy]

      def index
        render json: UserSmalltalk.where(user: current_user)
          .page(page)
          .per(per), root: :user_smalltalks, each_serializer: ::V1::UserSmalltalkSerializer, scope: { user: current_user }
      end

      private

      def page
        params[:page] || 1
      end
    end
  end
end
