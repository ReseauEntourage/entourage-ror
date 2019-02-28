class SessionsController < ApplicationController
  def new
    render layout: "login"
  end

  def create
    user = UserServices::UserAuthenticator.authenticate_by_phone_and_sms(phone: params[:phone], sms_code: params[:sms_code])

    if user
      session[:user_id] = user.id
      session[:admin_user_id] = user.admin ? user.id : nil

      if user.public?
        return redirect_to edit_public_user_user_path(user)
      end

      redirect_to root_url
    else
      flash[:error] = "Identifiants incorrects"
      redirect_to new_session_path
    end
  end

  def destroy
    session[:user_id] = nil
    session[:admin_user_id] = nil
    flash[:notice] = "Vous êtes déconnecté"
    redirect_to root_url
  end
end
