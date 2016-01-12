module Api
  module V1
    module Entourages
      class UsersController < Api::V1::BaseController
        def index
          return render file: 'mocks/users.json'
        end
      end
    end
  end
end