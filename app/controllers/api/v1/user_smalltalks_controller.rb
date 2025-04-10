module Api
  module V1
    class UserSmalltalksController < Api::V1::BaseController
      before_action :set_user_smalltalk, only: [:show, :update, :match, :destroy]
      before_action :ensure_is_creator, only: [:show, :update, :match, :destroy]

      def index
        render json: UserSmalltalk.where(user: current_user)
          .page(page)
          .per(per), root: :user_smalltalks, each_serializer: ::V1::UserSmalltalkSerializer, scope: { user: current_user }
      end

      def show
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
        @user_smalltalk.assign_attributes(user_smalltalk_params)

        if @user_smalltalk.save
          render json: @user_smalltalk, status: 200, serializer: ::V1::UserSmalltalkSerializer, scope: { user: current_user }
        else
          render json: {
            message: 'Could not update user_smalltalk', reasons: @user_smalltalk.errors.full_messages
          }, status: 400
        end
      end

      def match
        if @user_smalltalk.find_and_save_match!
          render json: { match: true, smalltalk_id: @user_smalltalk.smalltalk_id }, status: 200
        else
          render json: { match: false, smalltalk_id: nil }, status: 200
        end
      end

      def destroy
        if @user_smalltalk.update(deleted_at: Time.zone.now)
          render json: @user_smalltalk, root: "user", status: 200, serializer: ::V1::UserSmalltalkSerializer, scope: { user: current_user }
        else
          render json: {
            message: "Could not delete user_smalltalk", reasons: @user_smalltalk.errors.full_messages
          }, status: :bad_request
        end
      end

      private

      def set_user_smalltalk
        @user_smalltalk = UserSmalltalk.find_by_id_through_context(params[:id], params)

        render json: { message: 'Could not find user_smalltalk' }, status: 400 unless @user_smalltalk.present?
      end

      def ensure_is_creator
        render json: { message: 'unauthorized' }, status: :unauthorized unless @user_smalltalk.user == current_user
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
