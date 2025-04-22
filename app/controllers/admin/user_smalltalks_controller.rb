module Admin
  class UserSmalltalksController < Admin::BaseController
    before_action :set_user_smalltalk, only: [:match]

    def index
      @params = params.permit(:matched).to_h
      @matched = false
      @matched = ActiveModel::Type::Boolean.new.cast(params[:matched]) if params[:matched].present?

      @user_smalltalks = UserSmalltalk.includes(:user, :smalltalk)
        .with_match_filter(@matched)
        .order(updated_at: :desc)
        .page(page)
        .per(per)
    end

    def show
    end

    def edit
      @user_smalltalk = UserSmalltalk.find(params[:id])
    end

    def update
      @user_smalltalk = UserSmalltalk.find(params[:id])
      @user_smalltalk.assign_attributes(user_smalltalk_params)

      if @user_smalltalk.save
        redirect_to edit_admin_user_smalltalk_path(@user_smalltalk)
      else
        render :edit
      end
    end

    def new
      @user_smalltalk = UserSmalltalk.new
    end

    def create
      @user_smalltalk = UserSmalltalk.new(user_smalltalk_params)
      if @user_smalltalk.save
        redirect_to edit_admin_user_smalltalk_path(@user_smalltalk)
      else
        render :new
      end
    end

    def match
      @user_smalltalk.find_and_save_match!

      redirect_to admin_user_smalltalks_path
    end

    private

    def set_user_smalltalk
      @user_smalltalk = UserSmalltalk.find(params[:id])
    end

    def user_smalltalk_params
      params.require(:user_smalltalk).permit(:user_id, :match_format, :match_locality, :match_gender, :match_interest)
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
