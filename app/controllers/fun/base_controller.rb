module Fun
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_admin!

    def home
      if current_admin
        redirect_to fun_home_path
      else
        redirect_to new_admin_session_path
      end
    end
  end
end
