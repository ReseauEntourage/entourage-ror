class UsersController < ApplicationController

  def validation
    @user = User.find_by_email(params[:email])
  end
end
