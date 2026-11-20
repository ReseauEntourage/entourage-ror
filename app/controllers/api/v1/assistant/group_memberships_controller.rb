module Api
  module V1
    module Assistant
      # Joins a group in the name of the user, as the app does.
      class GroupMembershipsController < ActionsController
        def join
          run_action('group.join', { group: params[:id] }) do
            ::Assistant::Actions::JoinGroup.new(user: assistant_user, group_id: params[:id]).call
          end
        end
      end
    end
  end
end
