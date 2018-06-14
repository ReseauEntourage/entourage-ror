module Api
  module V1
    class LinksController < Api::V1::BaseController
      skip_before_filter :authenticate_user!
      skip_before_filter :ensure_community!

      def redirect
        if current_user.nil? && params[:id] != 'terms'
          return render json: {message: 'unauthorized'}, status: :unauthorized
        end

        user_id = UserServices::EncodedId.encode(current_user.id) if current_user

        redirections = {
          'pedagogic-content' =>
            'http://www.simplecommebonjour.org',
          'action-examples' =>
            'http://blog.entourage.social/quelles-actions-faire-avec-entourage',
          'donation' =>
            lambda do |user|
              url = "https://www.entourage.social/don" +
                      "?firstname=#{current_user.first_name}" +
                      "&lastname=#{current_user.last_name}" +
                      "&email=#{current_user.email}" +
                      "&external_id=#{current_user.id}" +
                      "&utm_medium=APP" +
                      "&utm_campaign=DEC2017"

              mixpanel.track("Clicked Menu Link", { "Link" => "Donation", "Campaign" => "Donation DEC2017" })
              if user.id % 2 == 0
                url + "&utm_source=APP-S1"
              else
                url + "&utm_source=APP-S2"
              end
            end,
          'atd-partnership' =>
            'https://www.atd-quartmonde.fr/entourage/',
          'faq' =>
              'https://blog.entourage.social/comment-utiliser-l-application-entourage/',
          'ethics-charter' =>
            lambda do |user|
              if user.pro?
                'https://blog.entourage.social/charte-ethique-maraudeur/'
              else
                'https://blog.entourage.social/charte-ethique-grand-public/'
              end
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
            'entourage' => 'https://docs.google.com/document/d/1Q8QC8ByEs8x837Df-lN-KQYHzxyx10awaEsD1Vk_JtM/pub',
            'pfp'       => 'https://docs.google.com/document/d/e/2PACX-1vSSd0XDqr7YU4DiWZfubsl43j2EImvLX2XOJaFJ0Cx1uxE06H5PMfnHgj1bl9lEHONuXeB7fPsfL6rY/pub'
          }[community.slug]
        }

        redirection = redirections[params[:id]]

        return head :not_found if redirection.nil?

        redirection = redirection.call(current_user) if redirection.respond_to?(:call)

        redirect_to redirection
      end
    end
  end
end
