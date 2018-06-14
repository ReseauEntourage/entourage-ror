module Api
  module V1
    module Tours
      class UsersController < Api::V1::Entourages::UsersController
        private
        def set_entourage
          @entourage = Tour.find(params[:tour_id])
        end

        def restrict_group_types!
          unless ['tour'].include?(@entourage.group_type)
            render json: {message: "This operation is not available for groups of type '#{@entourage.group_type}'"}, status: :bad_request
          end
        end
      end
    end
  end
end
