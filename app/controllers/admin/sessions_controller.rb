module Admin
  class SessionsController < Admin::BaseController
    skip_before_action :authenticate_admin!, except: [:switch_user]

    #used by active admin
    def logout
      session[:user_id] = nil
      session[:admin_user_id] = nil
      flash[:notice] = "Vous êtes déconnecté"
      redirect_to root_url
    end

    def switch_user
      session[:user_id] = params[:user_id].try(:to_i)
      @current_user = nil
      redirect_to root_url
    end
  end
end