module Api
  module V1
    module Entourages
      class InvitationsController < Api::V1::BaseController
        before_action :set_entourage
        before_action :restrict_group_types!

        #curl -X POST -d '{"invite": {"mode": "SMS", "phone_numbers": ["+33612345678", "+3361234569"]}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/entourages/139/invitations.json?token=azerty"
        def create
          phone_numbers = invite_params[:phone_numbers]

          return render_error(
            code: 'MISSING_PHONE_NUMBERS',
            message: 'phone_numbers must be an array of phone numbers',
            status: :bad_request
          ) if phone_numbers.blank?

          sms_invite = EntourageServices::BulkInvitationService.new(phone_numbers: phone_numbers,
                                                        entourage: entourage,
                                                        inviter: @current_user)
          sms_invite.send_invite do |on|
            on.success do |successfull_invites|
              render json: {"successfull_numbers": successfull_invites}, status: 201
            end

            on.failure do |successfull_invites, failed_invites|
              render json: {"successfull_numbers": successfull_invites, "failed_numbers": failed_invites}, status: 400
            end

            on.not_authorised do
              render json: {message: 'You cannot invite another user'}, status: 403
            end
          end
        end

        private
        attr_reader :entourage

        def set_entourage
          @entourage = Entourage.findable_by_id_or_uuid(params[:entourage_id])
        end

        def restrict_group_types!
          unless @entourage.community == 'entourage' && ['action', 'outing', 'group'].include?(@entourage.group_type)
            render json: {message: "This operation is not available for groups of type '#{@entourage.group_type}'"}, status: :bad_request
          end
        end

        def invite_params
          params.require(:invite).permit(:mode, phone_numbers: [])
        end
      end
    end
  end
end
