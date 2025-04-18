module Admin
  class UserSmalltalksController < Admin::BaseController
    before_action :set_user_smalltalk, only: [:match]

    def index
      @user_smalltalks = UserSmalltalk.includes(:user, :smalltalk).order(updated_at: :desc).page(page).per(per)
    end

    def match
      @user_smalltalk.find_and_save_match!

      redirect_to admin_user_smalltalks_path
    end

    private

    def set_user_smalltalk
      @user_smalltalk = UserSmalltalk.find(params[:id])
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
