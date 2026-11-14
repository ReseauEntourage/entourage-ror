module Api
  module V1
    module Assistant
      # Who is talking to the assistant: recognizes the account from its token and returns
      # the minimum the assistant may read about the user themselves, and nothing else.
      class IdentityController < BaseController
        # The action is not named index/show/create on purpose.
        def read
          render json: {
            id: assistant_user.uuid,
            firstName: assistant_user.first_name.presence,
            # City of the main address only, never its label (which can be a precise address).
            city: assistant_user.address&.city.presence
          }
        end
      end
    end
  end
end
