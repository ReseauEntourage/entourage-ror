module Api
  module V1
    module Entourages
      class UsersController < Api::V1::BaseController
        before_action :set_entourage

        def index
          render json: @entourage.entourages_users, root: "users", each_serializer: ::V1::EntouragesUserSerializer
        end

        def destroy
          return head :no_content
        end

        def update
          return head :no_content
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
      end
    end
  end
end