module Api
  module V1
    class AnnouncementsController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:icon, :avatar]

      def icon
        redirect_to view_context.asset_url("assets/announcements/icons/video.png")
      end

      def avatar
        redirect_to view_context.asset_url("assets/announcements/avatars/1.jpg")
      end

      def redirect
        mixpanel.track("Opened Announcement", { "Campaign" => "SCB_1.1" })
        redirect_to "http://www.simplecommebonjour.org/?p=4&utm_source=app&utm_medium=annonce&utm_campaign=SCB_1.1"
      end
    end
  end
end
