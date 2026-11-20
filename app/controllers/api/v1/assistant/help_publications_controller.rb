module Api
  module V1
    module Assistant
      # Publishes a request or an offer of help in the name of the user, with their own words.
      class HelpPublicationsController < ActionsController
        def publish_request
          publish('request', 'help_request.publish')
        end

        def publish_offer
          publish('offer', 'help_offer.publish')
        end

        private

        def publish type, action_type
          attributes = params.permit(:title, :description, :section, :postal_code, :latitude, :longitude, :recipient_consent_obtained).to_h.symbolize_keys

          run_action(action_type, attributes) do
            ::Assistant::Actions::PublishHelp.new(user: assistant_user, type: type, params: attributes).call
          end
        end
      end
    end
  end
end
