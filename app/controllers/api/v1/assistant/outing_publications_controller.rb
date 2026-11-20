module Api
  module V1
    module Assistant
      # Creates an outing in the name of the user, with the validations of the app.
      class OutingPublicationsController < ActionsController
        def publish
          attributes = params.permit(
            :title, :description, :latitude, :longitude, :online, :event_url, :other_interest, interests: [],
            metadata: %i[starts_at ends_at place_name street_address google_place_id place_limit reserved_female pmr kids_friendly]
          ).to_h.deep_symbolize_keys

          run_action('outing.publish', attributes) do
            ::Assistant::Actions::PublishOuting.new(user: assistant_user, params: attributes).call
          end
        end
      end
    end
  end
end
