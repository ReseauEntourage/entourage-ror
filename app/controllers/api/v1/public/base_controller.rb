module Api
  module V1
    module Public
      class BaseController < Api::V1::BaseController
        skip_before_action :authenticate_user!

      end
    end
  end
end
