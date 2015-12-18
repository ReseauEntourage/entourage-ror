module AuthHelper
  def admin_basic_login
    user = create :user, admin: true
    session[:admin_user_id] = user.id
    basic_login(user)
  end
  
  def manager_basic_login
    user = create :user, manager: true
    basic_login(user)
  end

  def basic_login(user)
    session[:user_id] = user.id
    return user
  end

end