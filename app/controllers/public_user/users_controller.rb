module PublicUser
  class UsersController < PublicUser::BaseController
    before_action :set_user

    def edit
    end

    def update
      if current_user.update(user_params)
        flash[:notice] = 'Vos informations ont bien été mises à jour'
        render :edit
      else
        render :edit
      end
    end

    private
    def set_user
      @user = current_user
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :phone, :email)
    end
  end
end
