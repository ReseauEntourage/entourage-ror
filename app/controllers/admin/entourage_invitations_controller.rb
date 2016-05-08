module Admin
  class EntourageInvitationsController < Admin::BaseController
    def index
      @entourage_invitations = EntourageInvitations.includes(:inviter).page(params[:page].per(params[:per]))
    end
  end
end