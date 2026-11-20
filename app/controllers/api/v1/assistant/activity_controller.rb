module Api
  module V1
    module Assistant
      # What the user did in the app, without the content of any message.
      class ActivityController < BaseController
        def read
          render json: ::Assistant::Presenters::Activity.new(assistant_user).as_json
        end
      end
    end
  end
end
