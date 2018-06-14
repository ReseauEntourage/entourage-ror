module Api
  module V1
    module Public
      class BaseController < Api::V1::BaseController
        skip_before_filter :authenticate_user!

      end
    end
  end
end
