module Api
  module V1
    module Assistant
      # Whether the participation of the user in an outing is already recorded (registration,
      # attendance), so that the assistant does not ask it again.
      class OutingParticipationController < BaseController
        def read
          outing = ::Outing.for_user(assistant_user).find_by_id_or_uuid!(params[:id])
          join_request = JoinRequest.find_by(joinable: outing, user: assistant_user)

          render json: {
            registered: join_request&.accepted? || false,
            confirmed: join_request&.accepted? && join_request.confirmed_at.present? || false,
            participated: join_request&.accepted? && join_request.participate_at.present? || false
          }
        end
      end
    end
  end
end
