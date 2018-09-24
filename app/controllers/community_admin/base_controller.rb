module CommunityAdmin
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :authenticate_user!

    helper_method :current_user, :community

    layout 'community_admin'

    def root
      redirect_to CommunityAdminService.after_sign_in_url(user: current_user)
    end

    def authenticate_user!
      if current_user.nil?
        flash[:error] = "Vous devez vous connecter pour accéder à cette page"
        return redirect_to new_community_admin_session_path(
          error: :login_required,
          continue: request.path
        )
      end
    end

    def sign_out
      session[:user_id] = nil
      @current_user = nil
    end

    def sign_in user
      session[:user_id] = user.id
      @current_user = nil
    end

    def current_user
      return @current_user if @current_user != nil
      return nil if session[:user_id].nil?

      @current_user = CommunityAdminService
        .coordinators(community)
        .find_by(id: session[:user_id])

      sign_out if @current_user.nil?

      @current_user
    end

    def community
      @community ||= begin
        $server_community
      end
    end
  end
end
