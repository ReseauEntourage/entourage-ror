module Api
  module V1
    module Assistant
      # Registers the user to an outing and cancels their registration, as the app does.
      class OutingRegistrationsController < ActionsController
        def register
          run_action('outing.join', { outing: params[:id] }) do
            ::Assistant::Actions::JoinOuting.new(user: assistant_user, outing_id: params[:id]).call
          end
        end

        def unregister
          run_action('outing.leave', { outing: params[:id] }) do
            ::Assistant::Actions::LeaveOuting.new(user: assistant_user, outing_id: params[:id]).call
          end
        end
      end
    end
  end
end
