module Api
  module V1
    module Assistant
      # The sheet of a group: its name, so that the preview of a request to join shows the real one.
      # A group that the app does not offer to this user (reserved to women) is not found.
      class GroupsController < BaseController
        def read
          group = ::Neighborhood.not_reserved_female_for(assistant_user).find_by_id_or_uuid!(params[:id])

          render json: { id: group.uuid_v2, name: group.name.presence }
        end
      end
    end
  end
end
