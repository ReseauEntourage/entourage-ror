module AuthHelper
  def admin_basic_login
    user = 'admin'
    password = '3nt0ur4g3'
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials user, password
  end
  
  def manager_basic_login
    user = create :user, manager: true
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials user.phone, user.sms_code
    return user
  end
end