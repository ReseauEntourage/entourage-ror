module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [:show, :messages, :edit, :update, :block, :unblock, :banish, :validate, :experimental_pending_request_reminder]

    def index
      @users = User.includes(:organization).order("last_name ASC").page(params[:page]).per(25)
    end

    def show
      redirect_to edit_admin_user_path(user)
    end

    def messages
      messages =
        @user.conversation_messages
        .where(messageable_type: :Entourage)
        .select("created_at, content, messageable_id as entourage_id")

      messages +=
        @user.entourages
        .select("created_at, description as content, id as entourage_id")

      @entourage_messages =
        messages
        .group_by(&:entourage_id)
        .sort_by { |_, ms| ms.map(&:created_at).max }
        .reverse

      @entourages = Hash[Entourage.where(id: @entourage_messages.map(&:first)).map { |e| [e.id, e] }]
    end

    def edit
    end

    def new
      @user = User.new(community: current_user.community)
    end

    def create
      organization = Organization.find(params[:user][:organization_id])
      builder = UserServices::ProUserBuilder.new(params: user_params, organization: organization)

      builder.create(send_sms: params[:send_sms].present?) do |on|
        on.success do |user|
          @user = user
          redirect_to admin_users_path, notice: "utilisateur créé"
        end

        on.failure do |user|
          @user = user
          render :new
        end
      end
    end

    def update
      if !user.pro? && user_params[:organization_id].present?
        user.user_type = 'pro'
        user.organization_id = user_params[:organization_id]
      end

      email_prefs_success = EmailPreferencesService.update(
        user: user, preferences: params[:email_preferences])

      user.assign_attributes(user_params)

      if user_params.key?(:roles)
        # the "placeholder" role is used in the view to make sure
        # that the user[roles][] parameter is sent even where no role
        # is selected
        user.roles = (user_params[:roles] || []) - ["placeholder"]
      end

      if email_prefs_success && @user.save
        redirect_to [:admin, user], notice: "utilisateur mis à jour"
      else
        flash.now[:error] = "Erreur lors de la mise à jour"
        render :edit
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
      params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :phone, :organization_id, :marketing_referer_id, :use_suggestions, :about, :accepts_emails, roles: [])
    end
  end

end
