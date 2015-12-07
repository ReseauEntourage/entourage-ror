class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  force_ssl if: :ssl_configured?

  helper_method :current_user, :user_logged_in
  before_filter :require_login

  def current_user
    @current_user ||= User.find_by_token params[:token]
  end

  def user_logged_in
    @user_logged_in ||= !current_user.nil?
  end

  def current_admin
    @current_admin ||= User.where(id: session[:user_id]).first
  end

  def authenticate_admin!
    unless current_admin
      flash[:alert] = "Vous devez vous authentifier avec un compte admin pour accéder à cette page"
      render new_session_path, status: 401, layout: "login"
    end
  end

  def require_login
    render 'unauthorized', status: :unauthorized unless user_logged_in
  end

  def ssl_configured?
    Rails.env.production?
  end
end
