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

      def create
        @user_smalltalk = UserSmalltalk.new(user_smalltalk_params)
        @user_smalltalk.user = current_user

        if @user_smalltalk.save
          render json: @user_smalltalk, status: 201, serializer: ::V1::UserSmalltalkSerializer, scope: { user: current_user }
        else
          render json: { message: "Could not create UserSmalltalk", reasons: @user_smalltalk.errors.full_messages }, status: 400
        end
      end

      def update
        return render json: { message: 'unauthorized' }, status: :unauthorized if @user_smalltalk.user != current_user

        @user_smalltalk.assign_attributes(user_smalltalk_params)

        if @user_smalltalk.save
          render json: @user_smalltalk, status: 200, serializer: ::V1::UserSmalltalkSerializer, scope: { user: current_user }
        else
          render json: {
            message: 'Could not update user_smalltalk', reasons: @user_smalltalk.errors.full_messages
          }, status: 400
        end
      end

      private

      def set_user_smalltalk
        @user_smalltalk = UserSmalltalk.find(params[:id])

        render json: { message: 'Could not find user_smalltalk' }, status: 400 unless @user_smalltalk.present?
      end

      def user_smalltalk_params
        params.require(:user_smalltalk).permit(:match_format, :match_locality, :match_gender, :match_interest)
      end

      def page
        params[:page] || 1
      end
    end
  end
end
