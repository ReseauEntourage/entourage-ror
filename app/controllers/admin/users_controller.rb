module Admin
  class UsersController < Admin::BaseController
    before_action :authenticate_admin!
    before_action :set_user, only: [:banish, :validate]

    def moderate
      @users = if params[:validation_status] == "blocked"
        User.blocked
      else
        User.validated
      end
      @users = @users.where("avatar_key IS NOT NULL").page(params[:page]).per(25)
    end

    def banish
      @user.block!
      redirect_to moderate_admin_users_path(validation_status: "blocked")
    end

    def validate
      @user.validate!
      redirect_to moderate_admin_users_path(validation_status: "validated")
    end

    private
    def set_user
      @user = User.find(params[:id])
    end
  end
end