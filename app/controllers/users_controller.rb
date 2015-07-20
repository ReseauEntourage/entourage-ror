class UsersController < ApplicationController

  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  skip_before_filter :require_login
  before_filter :admin_authentication, except: :login

  def index
    @users = User.all
    render status: 200
  end

  def create
    @user = User.new(user_params)
    if @user.save
      render "show", status: 201
    else
      @entity = @user
      render 'application/400', status: 400
    end
  end

  def update
    if params[:id] && User.find_by(id: params[:id])
      @user = User.find(params[:id])
      @user.update_attributes(user_params)
      render "show", status: 200
    else
      render '404', status: 404
    end
  end

  def destroy
    if params[:id] && User.find_by(id: params[:id])
      user = User.find(params[:id])
      user.destroy
      head 204
    else
      render '404', status: 404
    end
  end

  def login
    @user = User.find_by_email params[:email].downcase

    if @user.nil?
      render 'error', status: :bad_request
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name)
  end

end
