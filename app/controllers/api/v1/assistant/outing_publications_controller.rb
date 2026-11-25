module Api
  module V1
    module Assistant
      # Creates an outing in the name of the user, with the validations of the app.
      class OutingPublicationsController < ActionsController
        def publish
          attributes = {
            title: params[:title], description: params[:description], starts_at: params[:startsAt], ends_at: params[:endsAt],
            place: params[:place], reserved_female: params[:reservedFemale]
          }

          run_action('outing.publish', attributes) do
            ::Assistant::Actions::PublishOuting.new(user: assistant_user, params: attributes).call
          end
        end
      end
    end
  end
end
