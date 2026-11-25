module Api
  module V1
    module Assistant
      # The dedicated contact of the user, or its absence.
      class ReferentController < BaseController
        def read
          render json: ::Assistant::ReferentFinder.new(assistant_user).as_json
        end
      end
    end
  end
end
