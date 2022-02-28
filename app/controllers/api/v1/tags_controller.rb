module Api
  module V1
    class TagsController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:interests]

      def interests
        render json: { interests: Community.new(:entourage).interest_list }
      end
    end
  end
end
