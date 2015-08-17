class Organization::UsersController < GuiController

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
  
  private
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :email, :manager)
  end
  
end