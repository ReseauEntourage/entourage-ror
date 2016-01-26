module Api
  module V1
    module Entourages
      class UsersController < Api::V1::BaseController
        before_action :set_entourage
        before_action :set_entourage_user, only: [:update, :destroy]

        def index
          render json: @entourage.entourages_users, root: "users", each_serializer: ::V1::EntouragesUserSerializer
        end

        def destroy
          if @entourage_user.update(status: "rejected")
            head :no_content
          else
            render json: {message: 'Could not update entourage participation request status', reasons: @entourage_user.errors.full_messages}, status: :bad_request
          end
        end

        def update
          if @entourage_user.update(status: params[:user][:status])
            head :no_content
          else
            render json: {message: 'Could not update entourage participation request status', reasons: @entourage_user.errors.full_messages}, status: :bad_request
          end
        end

        def create
          entourage_user = EntouragesUser.new(entourage: @entourage, user: current_user)

          if entourage_user.save
            render json: entourage_user, root: "user", status: 201, serializer: ::V1::EntouragesUserSerializer
          else
            render json: {message: 'Could not create entourage participation request', reasons: entourage_user.errors.full_messages}, status: :bad_request
          end
        end

        private

        def set_entourage
          @entourage = Entourage.find(params[:entourage_id])
        end

        def set_entourage_user
          @entourage_user = EntouragesUser.where(entourage: @entourage, user: current_user).first!
        end
      end
    end
  end
end