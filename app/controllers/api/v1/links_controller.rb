module Api
  module V1
    class LinksController < Api::V1::BaseController
      skip_before_filter :authenticate_user!
      skip_before_filter :ensure_community!

      def redirect
        if current_user_or_anonymous.nil? && !params[:id].in?(['terms', 'privacy-policy'])
          return render json: {message: 'unauthorized'}, status: :unauthorized
        end

        user_id =
          if current_user
            UserServices::EncodedId.encode(current_user.id)
          else
            "anonymous"
          end

        redirections = {
          'pedagogic-content' =>
            'http://www.simplecommebonjour.org',
          'action-examples' =>
            'https://blog.entourage.social/quelles-actions-faire-avec-entourage/#site-content',
          'devenir-ambassadeur' =>
            'https://ambassadeurs.entourage.social',
          'donation' =>
            lambda do |user|
              url = "#{ENV['WEBSITE_URL']}/don"

              if !user.anonymous?
                url +=
                  "?firstname=#{user.first_name}" +
                  "&lastname=#{user.last_name}" +
                  "&email=#{user.email}" +
                  "&external_id=#{user.id}" +
                  "&utm_medium=APP" +
                  "&utm_campaign=DEC2017"

                  mixpanel.track("Clicked Menu Link", { "Link" => "Donation", "Campaign" => "Donation DEC2017" })
                if user.id % 2 == 0
                  url + "&utm_source=APP-S1"
                else
                  url + "&utm_source=APP-S2"
                end
              end
              url
            end,
          'atd-partnership' =>
            'https://www.atd-quartmonde.fr/entourage/',
          'faq' =>
              'https://blog.entourage.social/comment-utiliser-l-application-entourage/#site-content',
          'ethics-charter' =>
            lambda do |user|
              key = 'ethics-charter'
              key += '-pro' if user.community == :entourage && user.pro?
              key += '-preprod' if EnvironmentHelper.env != :production

              user.community.links[key] % {user_id: user_id}
            end,
          'feedback' =>
            lambda do |user|
              user.community.links['feedback'] % {user_id: user_id}
            end,
          'volunteering' =>
            "https://entourage-asso.typeform.com/to/U5MocH?user_id=#{user_id}",
          'propose-poi' =>
            "https://entourage-asso.typeform.com/to/h4PDuZ?user_id=#{user_id}",
          'terms' => {
            'entourage' => 'https://www.entourage.social/cgu/',
            'pfp'       => 'https://docs.google.com/document/d/e/2PACX-1vSSd0XDqr7YU4DiWZfubsl43j2EImvLX2XOJaFJ0Cx1uxE06H5PMfnHgj1bl9lEHONuXeB7fPsfL6rY/pub'
          }[community.slug],
          'privacy-policy' => {
            'entourage' => 'https://www.entourage.social/politique-de-confidentialite/',
            'pfp'       => 'https://docs.google.com/document/d/e/2PACX-1vS9nOfDChubzKpL5gEz-6sOjYAJ1Y2nJjjC1nI1Y-Y7ewP9pg1Z8Qvd4e0UkrE_AkZWTbsCvFzkOrlq/pub'
          }[community.slug]
        }

        redirection = redirections[params[:id]]

        return head :not_found if redirection.nil?

        redirection = redirection.call(current_user_or_anonymous) if redirection.respond_to?(:call)

        redirect_to redirection
      end
    end
  end
end
