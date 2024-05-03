module Api
  module V1
    class LinksController < Api::V1::BaseController
      skip_before_action :authenticate_user!
      skip_before_action :ensure_community!

      def redirect
        if current_user_or_anonymous.nil? && !params[:id].in?(['terms', 'privacy-policy', 'action_faq', 'propose-poi'])
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
          'event-brite' => 'https://www.eventbrite.fr/o/entourage-29770425367',
          'action-examples' =>
            'https://blog.entourage.social/quelles-actions-faire-avec-entourage/#site-content',
          'events-guide' =>
            'https://blog.entourage.social/2018/11/12/le-coin-des-assos-creer-un-evenement-sur-entourage/#site-content',
          'devenir-ambassadeur' =>
            'https://ambassadeurs.entourage.social',
          'donation' =>
            lambda do |user|
              url = "https://entourage.iraiser.eu/jedonne/~mon-don?utm_source=appentourage&utm_medium=formulaire&utm_campaign=dons2020"

              if !user.anonymous?
                url += "&" + {
                  firstname: user.first_name,
                  lastname: user.last_name,
                  email: user.email,
                  postcode: user.address&.postal_code,
                  utm_term: "db#{UserServices::EncodedId.encode(user.id)}"
                }.to_query
              else
                url += "&utm_term=anonymous"
              end

              url
            end,
          'faq' => {
            'entourage' => 'https://blog.entourage.social/2017/04/28/comment-utiliser-l-application-entourage/#index-faq',
            'pfp'       => 'https://docs.google.com/document/d/1fR6pEmhmCIBUJgzZ0CmFy9gzbMTXW5lFh7zxLDmbUco'
          }[community.slug],
          'ethics-charter' =>
            lambda do |user|
              key = 'ethics-charter'
              key += '-pro' if user.community == :entourage && user.pro?
              key += '-preprod' if EnvironmentHelper.env != :production

              user.community.links[key] % {user_id: user_id}
            end,
          'suggestion' =>
            "https://entourage-asso.typeform.com/to/TUpltC?user_id=#{user_id}",
          'feedback' =>
            lambda do |user|
              user.community.links['feedback'] % {user_id: user_id}
            end,
          'jobs' => 'https://www.entourage.social/nous-rejoindre/',
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
          }[community.slug],
          'action_faq' => 'https://blog.entourage.social/2017/04/28/comment-utiliser-l-application-entourage/#publier-une-action-solidaire',
          'hub_1' => 'https://entourage-asso.typeform.com/to/RyxV8mhG',
          'hub_2' => 'https://www.simplecommebonjour.org/',
          'hub_3' => 'https://www.eventbrite.fr/o/entourage-29770425367',
          'hub_faq'  => 'https://blog.entourage.social/2017/04/28/comment-utiliser-l-application-entourage/#index-faq',
          'how-to-present' => 'https://blog.entourage.social/2019/08/06/comment-mieux-presenter-entourage-a-une-personne-sdf/',
          'partner_action_faq' => 'https://blog.entourage.social/category/associations/'
        }

        redirection = redirections[params[:id]]

        return head :not_found if redirection.nil?

        redirection = redirection.call(current_user_or_anonymous) if redirection.respond_to?(:call)

        redirect_to redirection
      end
    end
  end
end
