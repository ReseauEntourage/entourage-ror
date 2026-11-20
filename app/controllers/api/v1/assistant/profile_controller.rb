module Api
  module V1
    module Assistant
      # The preferences and profile that the user declared.
      class ProfileController < BaseController
        def read
          render json: ::Assistant::Presenters::Profile.new(assistant_user).as_json
        end
      end
    end
  end
end
