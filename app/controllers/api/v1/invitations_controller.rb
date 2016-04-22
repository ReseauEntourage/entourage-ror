module Api
  module V1
    class InvitationsController < Api::V1::BaseController
      def index
        invitations = current_user.invitations
        render json: invitations, each_serializer: ::V1::EntourageInvitationSerializer
      end
    end
  end
end