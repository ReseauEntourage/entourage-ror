module Api
  module V1
    class AnnouncementsController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:icon, :avatar]

      def icon
        redirect_to view_context.asset_url("assets/announcements/icons/heart.png")
      end

      def avatar
        redirect_to view_context.asset_url("assets/announcements/avatars/1.jpg")
      end

      def redirect
        url = "https://www.entourage.social/don" +
                "?firstname=#{current_user.first_name}" +
                "&lastname=#{current_user.last_name}" +
                "&email=#{current_user.email}" +
                "&external_id=#{current_user.id}" +
                "&utm_medium=APP" +
                "&utm_campaign=DEC2017"

        mixpanel.track("Opened Announcement", { "Campaign" => "Donation DEC2017" })
        if current_user.id % 2 == 0
          redirect_to url + "&utm_source=APP-S1"
        else
          redirect_to url + "&utm_source=APP-S2"
        end
      end
    end
  end
end
