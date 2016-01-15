module Api
  module V1
    class FeedsController < Api::V1::BaseController
      def index
        render file: 'mocks/feeds.json'
      end
    end
  end
end