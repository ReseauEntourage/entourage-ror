module Api
  module V1
    module Assistant
      # Warns the organizer of an outing in the name of the user.
      class OrganizerMessagesController < ActionsController
        def deliver
          attributes = { outing_id: params[:id], kind: params[:kind], content: params[:content] }

          run_action('outing.notify_organizer', attributes) do
            ::Assistant::Actions::NotifyOrganizer.new(user: assistant_user, **attributes).call
          end
        end
      end
    end
  end
end
