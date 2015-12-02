module AuthHelper
  def admin_basic_login
    user = 'admin'
    password = '3nt0ur4g3'
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials user, password
  end
  
  def manager_basic_login
    user = create :user, manager: true
    session[:user_id] = user.id
    return user
  end
end