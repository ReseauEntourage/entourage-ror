module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [:show, :edit, :update, :block, :unblock, :banish, :validate, :experimental_pending_request_reminder]

    def index
      @users = User.type_pro.includes(:organization).order("last_name ASC").page(params[:page]).per(25)
    end

    def show
      render :edit
    end

    def edit
    end

    def new
      @user = User.new
    end

    def create
      organization = Organization.find(params[:user][:organization_id])
      builder = UserServices::ProUserBuilder.new(params: user_params, organization: organization)

      builder.create(send_sms: params[:send_sms].present?) do |on|
        on.success do |user|
          @user = user
          set_coordinated_organizations(user)
          redirect_to admin_users_path, notice: "utilisateur créé"
        end

        on.failure do |user|
          @user = user
          render :new
        end
      end
    end

    def update
      if @user.update(user_params)
        set_coordinated_organizations(user)
        render :edit, notice: "utilisateur mis à jour"
      else
        render :edit, alert: "Erreur lors de la mise à jour"
      end
    end

    def moderate
      @users = if params[:validation_status] == "blocked"
        User.blocked
      else
        User.validated
      end
      @users = @users.where("avatar_key IS NOT NULL").order("updated_at DESC").page(params[:page]).per(25)
    end

    def block
      @user.block!
      redirect_to [:admin, @user], flash: { success: "Utilisateur bloqué" }
    end

    def unblock
      @user.unblock!
      redirect_to [:admin, @user], flash: { success: "Utilisateur débloqué" }
    end

    def banish
      @user.block!
      UserServices::Avatar.new(user: user).destroy
      redirect_to moderate_admin_users_path(validation_status: "blocked")
    end

    def validate
      @user.validate!
      redirect_to moderate_admin_users_path(validation_status: "validated")
    end

    def experimental_pending_request_reminder
      reminders = @user.experimental_pending_request_reminders
      last_reminder_at = reminders.maximum(:created_at)
      reminders.create! if last_reminder_at.nil? || !last_reminder_at.today?
      redirect_to :back, flash: { _experimental_pending_request_reminder_created: 1 }
    end

    def fake
    end

    def generate
      @users = []
      @users << UserServices::FakeUser.new.user_without_tours
      user_with_tours = UserServices::FakeUser.new.user_with_tours
      ongoing_tour = user_with_tours.tours.where(status: "ongoing").first
      @users << user_with_tours
      @users << UserServices::FakeUser.new.user_joining_tour(tour: ongoing_tour)
      @users << UserServices::FakeUser.new.user_accepted_in_tour(tour: ongoing_tour)
      @users << UserServices::FakeUser.new.user_rejected_of_tour(tour: ongoing_tour)
      @users << UserServices::FakeUser.new.user_quitting_tour(tour: ongoing_tour)
      render :fake
    end

    private
    attr_reader :user

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :phone, :organization_id, :marketing_referer_id, :use_suggestions, :about)
    end

    def set_coordinated_organizations(user)
      coordinated_organizations = params.dig(:user, :coordinated_organizations)
      if coordinated_organizations
        user.coordinated_organizations = Organization.where(id: coordinated_organizations.select {|o| o.present?})
        user.save
      end
    end
  end

end
