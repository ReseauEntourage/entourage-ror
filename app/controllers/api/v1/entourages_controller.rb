module Api
  module V1
    class EntouragesController < Api::V1::BaseController
      def index
        render file: 'mocks/entourages.json'
      end

      def show
        render file: 'mocks/entourage.json'
      end

      def create
        render file: 'mocks/entourage.json'
      end
    end
  end
end