class GuiController < ApplicationController
  def require_login
    unauthorized! unless current_user
  end

  def unauthorized!
    flash[:alert] = "Vous devez vous authentifier pour accéder à cette page"
    redirect_to new_session_path
  end

  def current_user
    @current_user ||= User.where(id: session[:user_id]).first
  end
end