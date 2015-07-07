class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :current_user, :user_logged_in
  before_filter :require_login

  def current_user
    @current_user ||= User.find_by_token params[:token]
  end

  def user_logged_in
    @user_logged_in ||= !current_user.nil?
  end

  def require_login
    unless user_logged_in
      render 'unauthorized', status: :unauthorized
    end
  end

end
