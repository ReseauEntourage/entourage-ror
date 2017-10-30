module Api
  module V1
    class AnnouncementsController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:icon]

      def icon
        redirect_to view_context.asset_url("assets/announcements/icons/heart.png")
      end

      def redirect
        redirect_to "https://entourage.iraiser.eu/b/mon-don"
      end
    end
  end
end
