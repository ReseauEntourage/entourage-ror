module Api
  module V1
    class ApplicationsController < Api::V1::BaseController
      def create
        head :no_content
      end
    end
  end
end