module AuthHelper
  def admin_basic_login
    user = create :pro_user, admin: true
    session[:admin_user_id] = user.id
    basic_login(user)
  end

  def organization_admin_basic_login
    user = create :partner_user, partner_admin: true
    session[:org_admin_user_id] = user.id
    basic_login(user)
  end

  def manager_basic_login
    basic_login(create :pro_user, manager: true)
  end

  def user_basic_login
    basic_login(create :pro_user)
  end

  def basic_login(user)
    session[:user_id] = user.id
    return user
  end

end
