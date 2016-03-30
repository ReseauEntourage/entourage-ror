module Admin
  class AmbassadorsController < Admin::BaseController
    before_action :set_user, only: [:edit, :update]

    def index
      @users = User.type_public.page(params[:page]).per(params[:per])
    end

    def edit
    end

    def new
      @user = User.new
    end

    def create
      builder = UserServices::PublicUserBuilder.new(params: user_params)

      builder.create(send_sms: params[:send_sms].present?) do |on|
        on.create_success do |user|
          @user = user
          redirect_to admin_ambassadors_path, notice: "Ambassadeur créé"
        end

        on.create_failure do |user|
          @user = user
          render :new
        end
      end
    end

    def update
      if @user.update(user_params)
        render :edit, notice: "Ambassadeur mis à jour"
      else
        render :edit
      end
    end

    def search
      @users = User.type_public
                   .where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone = ?",
                          search_param,
                          search_param,
                          search_param,
                          params[:search])
                   .order("last_name ASC")
                   .page(params[:page])
                   .per(25)
      render :index
    end

    private
    attr_reader :user

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :phone)
    end

    def search_param
      "%#{params[:search]}%"
    end
  end
end