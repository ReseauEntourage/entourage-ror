module GoodWaves
  class InvitationsController < BaseController
    skip_before_action :authenticate_user!
    skip_before_action :ensure_profile_complete!

    def show
      @group = community.entourages.where(uuid_v2: params[:id]).first!
    end
  end
end
