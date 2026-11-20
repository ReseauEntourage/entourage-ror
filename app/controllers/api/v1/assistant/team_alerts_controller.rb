module Api
  module V1
    module Assistant
      # Passes a message approved by the user to the Entourage team (Slack).
      class TeamAlertsController < ActionsController
        def raise_alert
          attributes = { kind: params[:kind], content: params[:content] }

          run_action('team.alert', attributes) do
            ::Assistant::Actions::AlertTeam.new(user: assistant_user, **attributes).call
          end
        end
      end
    end
  end
end
