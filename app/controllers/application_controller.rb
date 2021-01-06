class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :current_user, :current_admin, :current_manager

  def authenticate_admin!
    login_error "Vous devez vous authentifier avec un compte admin pour accéder à cette page" unless current_admin
  end

  def authenticate_manager!
    login_error "Vous devez vous authentifier avec un compte manager pour accéder à cette page" unless current_manager
  end

  def authenticate_user!
    if current_user || current_admin
      UserServices::LoginHistoryService.new(user: current_user).record_login! unless current_admin
    else
      login_error "Vous devez vous authentifier pour accéder à cette page"
    end
  end

  def current_user
    return if session[:user_id].nil?
    @current_user ||= User.where(id: session[:user_id]).first
  end

  def current_admin
    return if session[:admin_user_id].nil?
    @current_admin ||= User.where(id: session[:admin_user_id]).first
  end

  def current_manager
    current_user if (current_user && (current_user.manager || current_user.admin))
  end

  def login_error(message)
    flash[:error] = message
    redirect_path =
      if request.get? && request.fullpath.presence != '/'
        new_session_path(continue: request.fullpath)
      else
        new_session_path
      end
    return redirect_to redirect_path
  end

  def ping
    head 200
  end
end
