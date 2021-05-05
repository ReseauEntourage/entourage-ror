module Api
  module V1
    class AnonymousUsersController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def create
        user = AnonymousUserService.create_user(community)
        render json: user, status: 201, serializer: ::V1::UserSerializer, scope: {user: user}
      end
    end
  end
end
