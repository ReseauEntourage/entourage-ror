module Api
  module V1
    class UserSmalltalksController < Api::V1::BaseController
      before_action :set_user_smalltalk, only: [:show, :update, :destroy]

      def index
        render json: UserSmalltalk.where(user: current_user)
          .page(page)
          .per(per), root: :user_smalltalks, each_serializer: ::V1::UserSmalltalkSerializer, scope: { user: current_user }
      end

      def show
        return render json: { message: 'unauthorized' }, status: :unauthorized if @user_smalltalk.user != current_user

        render json: @user_smalltalk, serializer: ::V1::UserSmalltalkSerializer, scope: { user: current_user }
      end

      private

      def set_user_smalltalk
        @user_smalltalk = UserSmalltalk.find(params[:id])

        render json: { message: 'Could not find user_smalltalk' }, status: 400 unless @user_smalltalk.present?
      end

      def page
        params[:page] || 1
      end
    end
  end
end
