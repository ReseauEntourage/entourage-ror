module Api
  module V1
    module Entourages
      class InvitationsController < Api::V1::BaseController
        before_action :set_entourage

        #curl -X POST -d '{"invite": {"mode": "SMS", "phone_numbers": ["+33612345678", "+3361234569"]}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/entourages/139/invitations.json?token=azerty"
        def create
          sms_invite = EntourageServices::BulkInvitationService.new(phone_numbers: params.dig("invite", "phone_numbers"),
                                                        entourage: entourage,
                                                        inviter: @current_user)
          sms_invite.send_invite do |on|
            on.success do |successfull_invites|
              render json: {"successfull_numbers": successfull_invites}, status: 201
            end

            on.failure do |successfull_invites, failed_invites|
              render json: {"successfull_numbers": successfull_invites, "failed_numbers": failed_invites}, status: 400
            end

            on.not_part_of_entourage do
              render json: {message: 'You are not accepted in this entourage, you cannot invite another user'}, status: 403
            end
          end
        end

        private
        attr_reader :entourage

        def set_entourage
          @entourage = Entourage.find(params[:entourage_id])
        end

        def invite_params
          params.require(:invite).permit(:mode, :phone_numbers)
        end
      end
    end
  end
end