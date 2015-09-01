class Organization::UsersController < GuiController
  attr_writer :sms_notification_service

  def index
    @new_user = User.new
  end
  
  def edit
    @user = User.find params[:id]
  end

  def create
    @user = User.new(user_params)
    @user.organization = @organization

    if @user.save
      redirect_to organization_users_url, notice: "L'utilisateur a été créé"
    else
      redirect_to organization_users_url, notice: "Erreur de création"
    end
  end

  def update
    @user = User.find params[:id]

    if @user.update_attributes(user_params)
      redirect_to organization_users_url, notice: "L'utilisateur a été sauvegardé"
    else
      flash[:notice] = "Erreur de modification"
      render action: "edit"
    end
  end

  def destroy
    @entity = User.find params[:id]
    @entity.destroy
    redirect_to organization_users_url, notice: "L'utilisateur a bien été supprimé"
  end
  
  def send_sms
    user = User.find_by id: params[:id]
    if user.nil?
      head 404
    else
      if user.organization == @current_user.organization
        sms_notification_service.send_notification(user.phone, "Bienvenue sur Entourage. Votre code est \"#{user.sms_code}\".")
        head 200
      else
        head 403
      end
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :email, :manager)
  end
  
  def sms_notification_service
    @sms_notification_service ||= SmsNotificationService.new
  end
  
end