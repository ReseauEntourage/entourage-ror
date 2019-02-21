module Admin
  class AmbassadorsController < Admin::BaseController
    def new
      @user = User.new
    end

    def create
      builder = UserServices::PublicUserBuilder.new(params: user_params, community: community)
      builder.create(send_sms: params[:send_sms].present?) do |on|
        on.success do |user|
          @user = user
          add_relation(params[:user_relation_id])
          redirect_to admin_users_path, notice: "Ambassadeur créé"
        end

        on.failure do |user|
          @user = user
          render :new
        end
      end
    end

    private
    attr_reader :user

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :phone, :marketing_referer_id, :organization_id, :use_suggestions, :accepts_emails)
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
