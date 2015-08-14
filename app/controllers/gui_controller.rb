class GuiController < ApplicationController
  def require_login
    if user = authenticate_with_http_basic { |u, p| User.find_by_phone_and_sms_code_and_manager(u, p, true) }
      @current_user = user
      @organization = @current_user.organization
    else
      request_http_basic_authentication
    end
  end
end