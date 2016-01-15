module Api
  module V1
    class FeedsController < Api::V1::BaseController
      skip_before_filter :authenticate_user!
      def index
        render file: 'mocks/feeds.json'
      end
    end
  end
end