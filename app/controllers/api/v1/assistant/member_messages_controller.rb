module Api
  module V1
    module Assistant
      # A first message to another member, in the name of the user.
      class MemberMessagesController < ActionsController
        def deliver
          attributes = { recipient: params[:id], content: params[:content] }

          run_action('member.first_message', attributes) do
            ::Assistant::Actions::SendMemberMessage.new(user: assistant_user, **attributes).call
          end
        end
      end
    end
  end
end
