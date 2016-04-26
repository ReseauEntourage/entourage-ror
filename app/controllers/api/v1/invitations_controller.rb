module Api
  module V1
    class InvitationsController < Api::V1::BaseController
      before_action :set_invitation, only: [:update, :destroy]

      def index
        invitations = current_user.invitations
        render json: invitations, each_serializer: ::V1::EntourageInvitationSerializer
      end

      def update
        return render json: "You tried to accept an invitation to another user", status: 403 if current_user != @invitation.invitee

        EntourageServices::InvitationService.new(invitation: @invitation).accept!
        head :no_content
      end

      def destroy

      end

      private

      def set_invitation
        @invitation = EntourageInvitation.find(params[:id])
      end
    end
  end
end