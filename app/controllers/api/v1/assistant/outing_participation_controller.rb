module Api
  module V1
    module Assistant
      # Whether the participation of the user in an outing is already recorded (registration,
      # attendance), so that the assistant does not ask it again, and can check that a journey
      # is founded. An unknown outing, or one hidden from the user, is a 404: no journey.
      class OutingParticipationController < BaseController
        def read
          outing = ::Outing.for_user(assistant_user).find_by_id_or_uuid!(params[:id])
          join_request = JoinRequest.find_by(joinable: outing, user: assistant_user)
          registered = join_request&.accepted? || false

          render json: { registered: registered, attended: registered && join_request.participate_at.present? }
        end
      end
    end
  end
end
