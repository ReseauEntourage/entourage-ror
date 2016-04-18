module Api
  module V1
    module Entourages
      class InvitationsController < Api::V1::BaseController
        before_action :set_entourage

        def create
          sms_invite = EntourageServices::SmsInvite.new(phone_number: invite_params[:phone_number], entourage: entourage)
          sms_invite.send_invite do |on|
            on.success do |invite|

            end

            on.failure do |invite|

            end
          end
          render json: :ok
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