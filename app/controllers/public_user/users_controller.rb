module PublicUser
  class UsersController < PublicUser::BaseController
    before_action :set_user

    def edit
    end

    def update
    end

    private
    def set_user
      @user = current_user
    end
  end
end