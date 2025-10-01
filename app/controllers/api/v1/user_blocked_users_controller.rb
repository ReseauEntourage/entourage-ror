module Api
  module V1
    class UserBlockedUsersController < Api::V1::BaseController
      def index
        render json: current_user.user_blocked_users, status: 200, each_serializer: ::V1::UserBlockedUserSerializer
      end

      def show
        render json: UserBlockedUser.find_by_user_id_and_blocked_user_id(
          current_user.id,
          params[:id]
        ), root: :user_blocked_user, status: 200, serializer: ::V1::UserBlockedUserSerializer
      end

      def create
        return create_one if blocked_user_id

        create_many
      end

      def create_one
        user_blocked_user = UserBlockedUser.find_or_initialize_by(user_id: current_user.id, blocked_user_id: blocked_user_id)

        if user_blocked_user.save
          render json: user_blocked_user, status: 201, serializer: ::V1::UserBlockedUserSerializer
        else
          render json: { message: 'Could not block user_blocked_user', reasons: user_blocked_user.errors.full_messages }, status: 400
        end
      end

      def create_many
        if current_user.update_attribute(:blocked_user_ids, blocked_user_ids)
          render json: current_user.user_blocked_users, status: 201, each_serializer: ::V1::UserBlockedUserSerializer
        else
          render json: { message: 'Could not block user_blocked_user', reasons: current_user.errors.full_messages }, status: 400
        end
      end

      def destroy
        return destroy_one if blocked_user_id

        destroy_many
      end

      def destroy_one
        user_blocked_user = UserBlockedUser.find_by(user_id: current_user.id, blocked_user_id: blocked_user_id)

        if user_blocked_user.delete
          render json: { user_blocked_user: :deleted }, status: 200
        else
          render json: { message: 'Could not unblock user_blocked_user', reasons: user_blocked_user.errors.full_messages }, status: 400
        end
      end

      def destroy_many
        user_blocked_users = UserBlockedUser.where(user_id: current_user.id, blocked_user_id: blocked_user_ids)

        if user_blocked_users.delete_all
          render json: { user_blocked_users: :deleted }, status: 200
        else
          render json: { message: 'Could not unblock user_blocked_user', reasons: user_blocked_users.errors.full_messages }, status: 400
        end
      end

      private

      def blocked_user_id
        params[:id] || params[:blocked_user_id]
      end

      def blocked_user_ids
        params[:blocked_user_ids]
      end
    end
  end
end
