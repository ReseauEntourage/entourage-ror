module Api
  module V1
    class UserBlockedUsersController < Api::V1::BaseController
      def index
        render json: current_user.user_blocked_users, status: 200, each_serializer: ::V1::UserBlockedUserSerializer
      end

      def show
        render json: UserBlockedUser.find_by_user_id_and_blocked_user_id(
          current_user.id,
          blocked_user_ids
        ), status: 200, serializer: ::V1::UserBlockedUserSerializer
      end

      def create
        if current_user.update_attribute(:blocked_user_ids, blocked_user_ids)
          render json: current_user.user_blocked_users, status: 201, each_serializer: ::V1::UserBlockedUserSerializer
        else
          render json: { message: "Could not block user_blocked_user", reasons: @user_blocked_user.errors.full_messages }, status: 400
        end
      end

      def destroy
        user_blocked_users = UserBlockedUser.where(user_id: current_user.id, blocked_user_id: blocked_user_ids)

        if user_blocked_users.delete_all
          render json: current_user.user_blocked_users, status: 200, each_serializer: ::V1::UserBlockedUserSerializer
        else
          render json: { message: "Could not unblock user_blocked_user", reasons: @user_blocked_user.errors.full_messages }, status: 400
        end
      end

      private

      def blocked_user_ids
        params[:blocked_user_ids].to_a +
          [params[:blocked_user_id]].compact +
          [params[:id]].compact
      end
    end
  end
end
