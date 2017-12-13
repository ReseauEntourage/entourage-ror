module Api
  module V1
    class AnnouncementsController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:icon, :avatar]

      def icon
        icon = {
          2 => :heart,
          3 => :pin
        }[params[:id].to_i]

        redirect_to view_context.asset_url("assets/announcements/icons/#{icon}.png")
      end

      def avatar
        redirect_to view_context.asset_url("assets/announcements/avatars/1.jpg")
      end

      def redirect
        case params[:id].to_i
        when 2
          url = "https://www.entourage.social/don" +
                  "?firstname=#{current_user.first_name}" +
                  "&lastname=#{current_user.last_name}" +
                  "&email=#{current_user.email}" +
                  "&external_id=#{current_user.id}" +
                  "&utm_medium=APP" +
                  "&utm_campaign=DEC2017"

          mixpanel.track("Opened Announcement", { "Campaign" => "Donation DEC2017" })
          if current_user.id % 2 == 0
            url += "&utm_source=APP-S1"
          else
            url += "&utm_source=APP-S2"
          end
        when 3
          hex_id = current_user.id.to_s(16)
          sig = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), '6db24fb6', hex_id).first(4)
          url = "https://entourage-asso.typeform.com/to/WIg5A9?user_id=#{hex_id}:#{sig}"
        end

        redirect_to url
      end
    end
  end
end
