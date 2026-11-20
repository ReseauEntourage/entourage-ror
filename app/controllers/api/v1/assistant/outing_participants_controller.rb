module Api
  module V1
    module Assistant
      # The people that the app shows to a member among the participants of an outing: accepted,
      # validated and not deleted or blocked, as in Api::V1::Outings::UsersController#index.
      class OutingParticipantsController < BaseController
        LIMIT = 100

        def read
          outing = ::Outing.for_user(assistant_user).find_by_id_or_uuid!(params[:id])
          join_requests = outing.join_requests.accepted

          render json: {
            participantsCount: join_requests.count,
            participants: join_requests.includes(:user).ordered_by_validated_users.limit(LIMIT).map do |join_request|
              ::Assistant::Presenters::Participant.new(join_request).as_json
            end
          }
        end
      end
    end
  end
end
