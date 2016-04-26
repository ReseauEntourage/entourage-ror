module Api
  module V1
    class InvitationsController < Api::V1::BaseController
      before_action :set_invitation, only: [:update, :destroy]
      before_action :check_invitation, only: [:update, :destroy]

      def index
        invitations = current_user.invitations
        render json: invitations, each_serializer: ::V1::EntourageInvitationSerializer
      end

      def update
        EntourageServices::InvitationService.new(invitation: @invitation).accept!
        head :no_content
      end

      def destroy
        EntourageServices::InvitationService.new(invitation: @invitation).reject!
        head :no_content
      end

      private

      def set_invitation
        @invitation = EntourageInvitation.find(params[:id])
      end

      def check_invitation
        return render json: "You tried to accept an invitation to another user", status: 403 if current_user != @invitation.invitee
      end
    end
  end
end