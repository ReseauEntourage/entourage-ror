class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  force_ssl if: :ssl_configured?

  helper_method :current_user, :current_admin


  def authenticate_admin!
    login_error "Vous devez vous authentifier avec un compte admin pour accéder à cette page" unless current_admin
  end

  def authenticate_user!
    if current_user
      UserServices::LoginHistoryService.new(user: current_user).record_login!
    else
      login_error "Vous devez vous authentifier pour accéder à cette page"
    end
  end

  def authenticate_manager!
    login_error "Vous devez vous authentifier avec un compte manager pour accéder à cette page" unless current_user && (current_user.manager || current_user.admin)
  end

  def current_user
    @current_user = User.where(id: session[:user_id]).first
  end

  def current_admin
    @current_admin ||= User.where(id: session[:admin_user_id]).first
  end

  def login_error(message)
    flash[:error] = message
    return redirect_to new_session_path
  end

  def ssl_configured?
    Rails.env.production?
  end
end
