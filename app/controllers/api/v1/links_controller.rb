module Api
  module V1
    class LinksController < Api::V1::BaseController
      def redirect
        redirections = {
          'pedagogic-content' =>
            'http://www.simplecommebonjour.org',
          'action-examples' =>
            'http://blog.entourage.social/quelles-actions-faire-avec-entourage',
          'donation' =>
            'https://entourage.iraiser.eu',
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
            end
        }

        redirection = redirections[params[:id]]

        return head :not_found if redirection.nil?

        redirection = redirection.call(current_user) if redirection.respond_to?(:call)

        redirect_to redirection
      end
    end
  end
end
