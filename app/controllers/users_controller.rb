class UsersController < GuiController
  attr_writer :sms_notification_service, :url_shortener
  before_filter :authenticate_manager!, except: [:edit, :update]
  before_filter :get_user, only: [:edit, :update, :destroy, :send_sms]
  
  def edit
  end

  def index
    @users = current_user.organization.users.order(:last_name,:first_name)
    @new_user = User.new
  end

  def create
    builder = UserServices::UserBuilder.new(params:user_params, organization:current_user.organization)
    if builder.create
      redirect_to users_url, notice: "L'utilisateur a été créé"
    else
      redirect_to users_url, notice: "Erreur de création"
    end
  end

  def update
    if @user.update_attributes(user_params)
      redirect_to edit_user_url(@user), notice: "L'utilisateur a été sauvegardé"
    else
      flash[:notice] = "Erreur de modification"
      render action: "edit"
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: "L'utilisateur a bien été supprimé"
  end

  def send_sms
    UserServices::SMSSender.new(user: @user).send_welcome_sms!
    render json: {status: "message sent"}
  end

  private
  
  def get_user
    @user = User.find(params[:id])
    if @user.organization != current_user.organization
      head :forbidden
    end
  end
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :email, :manager)
  end

end