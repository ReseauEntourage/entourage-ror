class SessionsController < ApplicationController
  skip_before_filter :require_login

  def new
    render layout: "login"
  end

  def create
    user_phone = Phone::PhoneBuilder.new(phone: params[:phone]).format
    user = User.where(phone: user_phone, sms_code: params[:sms_code]).first
    if user
      session[:user_id] = user.id
      redirect_to root_url
    else
      flash[:error] = "Identifiants incorrects"
      redirect_to new_session_path
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Vous êtes déconnecté"
    redirect_to root_url
  end
end