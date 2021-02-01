module GoodWaves
  class InvitationsController < BaseController
    skip_before_action :authenticate_user!
    skip_before_action :ensure_profile_complete!

    def show
      @group = community.entourages.where(uuid_v2: params[:id]).first!

      is_ios = request.user_agent.match?(/\b(iPhone|iPod)\b/)
      is_android = request.user_agent.match?(/Android/)
      is_mobile = is_ios || is_android

      @open_url =
        if is_mobile
          "#{ENV['DEEPLINK_SCHEME']}://entourage/#{@group.uuid_v2}"
        else
          @group.share_url
        end

      @store_url =
        if is_ios
          "https://apps.apple.com/app/apple-store/id1072244410?pt=118066461&mt=8"
        elsif is_android
          "https://play.google.com/store/apps/details?id=social.entourage.android"
        end
    end
  end
end
