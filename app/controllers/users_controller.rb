class UsersController < ApplicationController

  skip_before_filter :require_login

  def login
    @user = User.find_by_email params[:email]

    if @user.nil?
      render 'error', status: :bad_request
    end
  end
end
