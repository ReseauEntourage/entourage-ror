class UsersController < ApplicationController
  attr_writer :sms_notification_service, :url_shortener
  before_action :authenticate_user!
  before_action :authenticate_manager!, only: [:index, :edit, :update]
  before_action :set_user, only: [:edit, :update, :destroy, :send_sms]

  def edit
    @user_presenter = UserPresenter.new(user: @current_user)
  end

  def index
    @users = current_user.organization.users.order(:last_name,:first_name)
    @user = User.new
    @user_presenter = UserPresenter.new(user: @user)
  end

  def create
    builder = UserServices::ProUserBuilder.new(params:user_params, organization:current_user.organization)
    send_sms = params[:send_sms] == "1"

    render_after_error = Proc.new do |user|

    end

    builder.create_or_upgrade(send_sms: send_sms) do |on|
      on.success do |user|
        redirect_to users_url, notice: "L'utilisateur a été créé"
      end

      on.failure do |user|
        @user = user
        @user_presenter = UserPresenter.new(user: @user)
        @users = current_user.organization.users.order(:last_name,:first_name)
        render :index, alert: "Erreur de création"
      end
    end
  end

  def update
    builder = UserServices::ProUserBuilder.new(params: user_params)
    if builder.update(user: @user)
      redirect_to edit_user_url(@user), notice: "L'utilisateur a été sauvegardé"
    else
      flash[:notice] = "Erreur de modification"
      render action: "edit"
    end
  end

  def destroy
    if @user == current_user
      flash[:notice] = "Vous ne pouvez pas vous retirer vous-même de l'organisation"
      redirect_to users_url
      return
    end

    @user.assign_attributes(
      user_type: :public,
      organization: nil,
      manager: false
    )

    if @user.save
      flash[:success] = "L'utilisateur a été retiré de votre organisation"
      redirect_to users_url
    else
      flash[:error] = "Erreur : #{@user.errors.full_messages.to_sentence}"
      redirect_to users_url
    end
  end

  def send_sms
    UserServices::SmsSender.new(user: @user).regenerate_sms!
    redirect_to users_url, notice: "Le sms a bien été envoyé"
  end

  private

  def set_user
    @user = User.find(params[:id])
    if @user.organization != current_user.organization
      head :forbidden
    end
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :email, :manager, :simplified_tour)
  end

end
