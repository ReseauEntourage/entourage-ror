module Api
  module V1
    class UserBlockedUsersController < Api::V1::BaseController
      def index
        render json: current_user.user_blocked_users, status: 200, each_serializer: ::V1::UserBlockedUserSerializer
      end

      def show
      end

      def create
        @user_blocked_user = UserBlockedUser.unscoped.find_or_create_by(
          user_id: current_user.id,
          blocked_user_id: user_blocked_user_params[:blocked_user_id]
        )

        if @user_blocked_user.update_attribute(:status, :blocked)
          render json: @user_blocked_user, status: 201, serializer: ::V1::UserBlockedUserSerializer
        else
          render json: { message: "Could not block user_blocked_user", reasons: @user_blocked_user.errors.full_messages }, status: 400
        end
      end

      def destroy
        @user_blocked_user = UserBlockedUser.find_by_user_id_and_blocked_user_id(current_user.id, params[:id])

        return render json: {}, status: 200 unless @user_blocked_user

        if @user_blocked_user.update_attribute(:status, :not_blocked)
          render json: @user_blocked_user, status: 200, serializer: ::V1::UserBlockedUserSerializer
        else
          render json: { message: "Could not unblock user_blocked_user", reasons: @user_blocked_user.errors.full_messages }, status: 400
        end
      end

      private

      def user_blocked_user_params
        params.require(:user_blocked_user).permit(:blocked_user_id)
      end
    end
  end
end
