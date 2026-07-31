module Admin
  class BaseController < ApplicationController
    layout 'admin'

    before_action :authenticate_admin!

    rescue_from ActionController::InvalidAuthenticityToken do
      redirect_back fallback_location: admin_neighborhood_message_broadcasts_path,
        alert: "Une erreur de session est survenue, merci de réessayer."
    end

    def home
      if current_admin
        redirect_to admin_actions_path
      else
        redirect_to new_admin_session_path
      end
    end

    def community
      @community ||= begin
        $server_community
      end
    end

    def page
      params[:page] || 1
    end

    def per
      [params[:per] || 25, 25].min
    end

    protected

    def ensure_moderator!
      unless current_user.roles.include?(:moderator)
        render text: "Cette action nécessite d'être modérateur", status: :unauthorized
      end
    end
  end
end
