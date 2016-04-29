module Api
  module V1
    module Entourages
      class InvitationsController < Api::V1::BaseController
        before_action :set_entourage

        def create
          sms_invite = EntourageServices::SmsInvite.new(phone_number: invite_params[:phone_number],
                                                        entourage: entourage,
                                                        inviter: @current_user)
          sms_invite.send_invite do |on|
            on.success do |invite|
              render json: invite, root: "invite", status: 201, serializer: ::V1::EntourageInvitationSerializer
            end

            on.failure do |error|
              render json: {message: 'Could not create entourage invitation', reasons: error.message}, status: :bad_request
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
          params.require(:invite).permit(:mode, :phone_number)
        end
      end
    end
  end
end