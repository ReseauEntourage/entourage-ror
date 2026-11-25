module Api
  module V1
    module Assistant
      # Posts a message in the discussion of an outing in the name of the user (a member of the outing).
      class DiscussionMessagesController < ActionsController
        def deliver
          attributes = { outing_id: params[:id], message: params[:message] }

          run_action('outing.discussion_message', attributes) do
            ::Assistant::Actions::PostDiscussionMessage.new(user: assistant_user, **attributes).call
          end
        end
      end
    end
  end
end
