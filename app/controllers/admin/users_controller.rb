module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [:show, :messages, :engagement, :edit, :update, :block, :unblock, :download_export, :send_export, :anonymize, :banish, :validate, :experimental_pending_request_reminder]

    def index
      @params = params.permit([:status]).to_h
      @status = params[:status].presence&.to_sym
      @status = :all unless @status.in?([:engaged, :not_engaged, :blocked, :deleted, :admin, :pending])

      @users = current_user.community.users

      @users = @users.engaged if @status && @status == :engaged
      @users = @users.not_engaged if @status && @status == :not_engaged
      @users = @users.blocked if @status && @status == :blocked
      @users = @users.deleted if @status && @status == :deleted
      @users = @users.where(admin: true) if @status && @status == :admin
      @users = @users.where(id: UserPhoneChange.pending_user_ids) if @status && @status == :pending

      @users = @users.includes(:organization).order("last_name ASC").page(params[:page]).per(25)
    end

    def show
      redirect_to edit_admin_user_path(user)
    end

    def messages
      user_id = params[:id]
      sanitized_user_id = ActiveRecord::Base.connection.quote user_id

      entourages = Entourage
        .joins("LEFT JOIN conversation_messages on conversation_messages.messageable_type = 'Entourage' and conversation_messages.messageable_id = entourages.id and conversation_messages.user_id = #{sanitized_user_id}")
        .where([
          'conversation_messages.user_id is not null or entourages.user_id = ?',
          user_id
        ])
        .group('entourages.id')
        .order('GREATEST(entourages.created_at, MAX(conversation_messages.created_at)) desc')
        .page(params[:page]).per(10)

      messages = ConversationMessage
        .where(user_id: user_id, messageable_type: :Entourage, messageable_id: entourages)
        .select('created_at, content, messageable_id as entourage_id')

      messages += entourages.select('entourages.created_at, entourages.description as content, entourages.id as entourage_id')

      @entourage_messages =
        messages
        .group_by(&:entourage_id)
        .sort_by { |_, ms| ms.map(&:created_at).max }
        .reverse

      @entourages = Hash[entourages.map { |e| [e.id, e] }]
      @entourages_paginate = entourages
    end

    def engagement
    end

    def edit
    end

    def new
      @user = new_user
    end

    def create
      if user_params[:organization_id].present?
        organization = Organization.find(user_params[:organization_id])
        builder = UserServices::ProUserBuilder.new(params: user_params, organization: organization)
      else
        builder = UserServices::PublicUserBuilder.new(params: user_params, community: community)
      end

      builder.create(send_sms: params[:send_sms].present?) do |on|
        on.success do |user|
          return redirect_to admin_users_path, notice: "utilisateur créé"
        end

        on.invalid_phone_format do
          @user = new_user
          @user.assign_attributes(user_params)
          @user.errors.add(:phone)
        end

        on.duplicate { |user| @user = user }
        on.failure   { |user| @user = user }
      end

      # if we reach here, there was an error
      render :new
    end

    def update
      if !user.pro? && user_params[:organization_id].present?
        user.user_type = 'pro'
        user.organization_id = user_params[:organization_id]
      end

      email_prefs_success = EmailPreferencesService.update(
        user: user, preferences: (params.permit([:email_preferences])[:email_preferences] || {}))

      user.assign_attributes(user_params)
      user.encrypted_password = nil if user.sms_code_changed?
      UserService.sync_roles(user)

      moderation = user.moderation || user.build_moderation
      moderation.assign_attributes(moderation_params)

      # the browser can transform \n to \r\n and push the text over the
      # 200 char limit.
      user.about.gsub!(/\r\n/, "\n")

      saved = false
      begin
        ApplicationRecord.transaction do
          UserServices::RequestPhoneChange.record_phone_change!(user: user, admin: current_user) if user.phone_changed?
          user.save! if user.changed?
          moderation.save! if moderation.changed?
          saved = true
        end
      rescue ActiveRecord::RecordInvalid
      end

      if email_prefs_success && saved
        redirect_to [:admin, user], notice: "utilisateur mis à jour"
      else
        flash.now[:error] = "Erreur lors de la mise à jour"
        render :edit
      end
    end

    def moderate
      @users = if params[:validation_status] == "blocked"
        User.blocked
      elsif params[:validation_status] == "anonymized"
        User.anonymized
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
      redirect_back(fallback_location: root_path, flash: { _experimental_pending_request_reminder_created: 1 })
    end

    def download_export
      send_file UserServices::Exporter.new(user: @user).csv, filename: "users-personal-data-#{@user.phone.parameterize}.csv", type: "application/csv"
    end

    def send_export
      UserServices::Exporter.new(user: @user).export(cci: current_user)
      redirect_to [:admin, @user], flash: { success: "Export envoyé par mail" }
    end

    def anonymize
      @user.anonymize!
      UserServices::Avatar.new(user: @user).destroy
      redirect_to [:admin, @user], flash: { success: "Utilisateur anonymisé" }
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
      @user = current_user.community.users.find(params[:id])
    end

    def new_user
      User.new(community: current_user.community, user_type: :public)
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :phone, :organization_id, :use_suggestions, :about, :accepts_emails, :targeting_profile, :partner_id, :admin)
    end

    def moderation_params
      params.require(:user_moderation).permit(
        :skills, :expectations, :acquisition_channel
      )
    end
  end

end
