module Api
  module V1
    class AnnouncementsController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: [:icon]
      skip_before_action :ensure_community!,  only: [:icon]
      allow_anonymous_access only: [:index, :redirect]

      def index
        announcements = FeedServices::AnnouncementsService.announcements_for_user(current_user_or_anonymous)

        # @fixme to_a prevents active_record_serializer to determine model_name
        # @see FeedServices::AnnouncementsService.announcements_for_user
        render json: announcements, root: :announcements, each_serializer: ::V1::AnnouncementSerializer, scope: {
          user: current_user_or_anonymous,
          base_url: request.base_url
        }
      end

      def icon
        # https://material.io/resources/icons/
        # white 48dp png
        # convert [...]-white-48dp/2x/[...]_white_48dp.png -gravity center -crop 84x84+0+0 [...].png
        # ImageOptim
        announcement = Announcement.find_by(id: params[:id])
        icon = announcement.icon
        redirect_to view_context.asset_url("assets/announcements/icons/#{icon}.png")
      end

      def redirect
        announcement = Announcement.find_by(id: params[:id])
        url = announcement.url

        begin
          uri = URI(url)
          url_params = CGI.parse(uri.query || '')
          {
            utm_source: 'app',
            utm_medium: 'announcement-card'
          }.each do |key, value|
            url_params[key] = value unless url_params.key?(key.to_s)
          end
          uri.query = URI.encode_www_form(url_params).presence
          url = uri.to_s
        rescue => e
          Raven.capture_exception(e)
        end

        redirect_to url
      end
    end
  end
end
