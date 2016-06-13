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
        on.success do |user|
          @user = user
          add_relation(params[:user_relation_id])
          redirect_to admin_ambassadors_path, notice: "Ambassadeur créé"
        end

        on.failure do |user|
          @user = user
          render :new
        end
      end
    end

    def update
      if @user.update(user_params)
        add_relation(params[:user_relation_id])
        render :edit, notice: "Ambassadeur mis à jour"
      else
        render :edit
      end
    end

    private
    attr_reader :user

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :phone, :marketing_referer_id)
    end

    def add_relation(user_relation_id)
      if user_relation_id
        UserServices::UserRelationshipBuilder.new(source_user_id: @user.id,
                                                  target_user_ids: [user_relation_id],
                                                  relation_type: UserRelationship::TYPE_INVITE).create
      end
    end
  end
end