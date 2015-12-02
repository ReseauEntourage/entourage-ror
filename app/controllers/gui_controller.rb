class GuiController < ApplicationController
  # def require_login
  #   if user = authenticate_with_http_basic { |u, p| User.find_by_phone_and_sms_code_and_manager(u, p, true) }
  #     @current_user = user
  #     @organization = @current_user.organization
  #   else
  #     request_http_basic_authentication
  #   end
  # end

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