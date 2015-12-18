module Admin
  class SessionsController < Admin::BaseController
    before_action :authenticate_admin!, only: [:switch_user]

    def logout
      session[:user_id] = nil
      flash[:notice] = "Vous êtes déconnecté"
      redirect_to root_url
    end

    def switch_user
      session[:user_id] = params[:user_id]
      redirect_to root_url
    end
  end
end