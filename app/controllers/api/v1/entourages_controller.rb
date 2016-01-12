module Api
  module V1
    class EntouragesController < Api::V1::BaseController
      def index
        render file: 'mocks/entourages.json'
      end
    end
  end
end