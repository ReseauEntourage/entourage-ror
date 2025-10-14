class SessionsController < ApplicationController
  def new
    render layout: 'login'
  end

  def create
    head 200
  end

  def destroy
    session[:user_id] = nil
    session[:admin_user_id] = nil
    flash[:notice] = 'Vous êtes déconnecté'
    redirect_to root_url
  end
end
