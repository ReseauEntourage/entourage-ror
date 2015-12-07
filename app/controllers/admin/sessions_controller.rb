module Admin
  class SessionsController < Admin::BaseController
    skip_before_filter :require_login

    def logout
      session[:user_id] = nil
      flash[:notice] = "Vous êtes déconnecté"
      redirect_to root_url
    end
  end
end