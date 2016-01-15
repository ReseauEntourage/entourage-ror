module Api
  module V1
    module Entourages
      class UsersController < Api::V1::BaseController
        def index
          return render file: 'mocks/users.json'
        end

        def destroy
          return head :no_content
        end

        def update
          return head :no_content
        end

        def create
          return head :no_content
        end
      end
    end
  end
end