module Admin
  class SessionsController < Admin::BaseController
    skip_before_action :authenticate_admin!, except: [:switch_user]

    def new
      render layout: 'login'
    end

    def create
      user = UserServices::UserAuthenticator.authenticate_by_phone_and_admin_password(phone: params[:phone], admin_password: params[:admin_password])

      if user && user.admin
        session[:user_id] = user.id
        session[:admin_user_id] = user.id
        cookies.encrypted[:admin_user_id] = user.id

        redirect_to(params[:continue].presence || root_path)
      else
        flash[:error] = user ? 'Votre profil doit être admin' : 'Identifiants incorrects'
        redirect_path =
          if params[:continue].present?
            new_admin_session_path(continue: params[:continue])
          else
            new_admin_session_path
          end
        redirect_to redirect_path
      end
    end

    #used by active admin
    def logout
      session[:user_id] = nil
      session[:admin_user_id] = nil
      cookies.delete(:admin_user_id)
      flash[:notice] = 'Vous êtes déconnecté'
      redirect_to root_url
    end

    def switch_user
      session[:user_id] = params[:user_id].try(:to_i)
      @current_user = nil
      redirect_to root_url
    end
  end
end
