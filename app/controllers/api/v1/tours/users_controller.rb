module Api
  module V1
    module Tours
      class UsersController < Api::V1::Entourages::UsersController
        def set_entourage
          @entourage = Tour.find(params[:tour_id])
        end
      end
    end
  end
end