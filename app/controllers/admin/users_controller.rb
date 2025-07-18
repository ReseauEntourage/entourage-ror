module Admin
  class UsersController < Admin::BaseController
    LAST_SIGN_IN_AT_EXPORT = 1.year.ago

    before_action :set_user, only: [:show, :messages, :engagement, :rpush_notifications, :neighborhoods, :outings, :history, :blocked_users, :edit, :update, :edit_block, :block, :temporary_block, :unblock, :cancel_phone_change_request, :download_export, :send_export, :anonymize, :destroy_avatar, :banish, :validate, :experimental_pending_request_reminder, :new_spam_warning, :create_spam_warning]

    def index
      @params = params.permit([:profile, :engagement, :status, :role, :search, q: [:country_eq, :postal_code_start, :postal_code_not_start_all]]).to_h

      @status = get_status
      @role = get_role

      @users = filtered_users.includes(:address).order("created_at DESC").page(params[:page]).per(25)
    end

    def search
      if params[:query].present?
        @users = User
          .validated
          .select(:id, :first_name, :last_name, :phone)
          .where(deleted: false)
          .where('first_name ILIKE ? OR phone LIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
          .limit(25)
          .sort_by(&:first_name)
      else
        @users = User.none
      end

      respond_to do |format|
        format.json { render json: @users.map { |user| { id: user.id, first_name: user.first_name, last_name: user.last_name, phone: user.phone } } }
      end
    end

    def show
      redirect_to edit_admin_user_path(user)
    end

    def messages
      user_id = params[:id]
      sanitized_user_id = ActiveRecord::Base.connection.quote user_id

      entourages = Entourage
        .joins("LEFT JOIN chat_messages on chat_messages.messageable_type = 'Entourage' and chat_messages.messageable_id = entourages.id and chat_messages.user_id = #{sanitized_user_id}")
        .where([
          'chat_messages.user_id is not null or entourages.user_id = ?',
          user_id
        ])
        .group('entourages.id')
        .order(Arel.sql('GREATEST(entourages.created_at, MAX(chat_messages.created_at)) desc'))
        .page(params[:page]).per(10)

      messages = ChatMessage
        .where(user_id: user_id, messageable_type: :Entourage, messageable_id: entourages)
        .select('created_at, content, messageable_id, status, deleter_id, deleted_at')

      messages += entourages.select('entourages.created_at, entourages.description as content, entourages.id as messageable_id')

      @entourage_messages =
        messages
        .group_by(&:messageable_id)
        .sort_by { |_, ms| ms.map(&:created_at).max }
        .reverse

      @entourages = Hash[entourages.map { |e| [e.id, e] }]
      @entourages_paginate = entourages
    end

    def engagement
    end

    def rpush_notifications
      @user_applications = UserApplication.where(user_id: @user.id)
        .select(:push_token, :device_os, :version, :notifications_permissions)
        .order(updated_at: :desc)
        .limit(3)

      @rpush_notifications = Rpush::Client::ActiveRecord::Notification.where(
        device_token: @user_applications.map(&:push_token)
      ).order(id: :desc).limit(25)
    end

    def neighborhoods
      @join_requests = user
        .join_requests
        .where(joinable_type: :Neighborhood)
        .includes(joinable: :chat_messages)
        .order(status: :asc, created_at: :desc)
    end

    def outings
      @join_requests = user
        .join_requests
        .where(joinable_type: :Entourage)
        .where("joinable_id in (select entourages.id from entourages where group_type = 'outing')")
        .includes(joinable: :chat_messages)
        .order(created_at: :desc)
    end

    def history
      @histories = UserServices::History.new(user).get

      @sms_deliveries_count = @histories.select do |history|
        history[:kind] == :sms
      end.count

      @block_count = @histories.select do |history|
        history[:kind] == :block
      end.count
    end

    def blocked_users
      @user_blocked_users = user
        .user_blocked_users
        .order("user_blocked_users.created_at desc")
    end

    def edit
    end

    def new
      @user = new_user
    end

    def create
      UserServices::PublicUserBuilder.new(params: user_params, community: community).create(send_sms: params[:send_sms].present?) do |on|
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
      email_prefs_success = EmailPreferencesService.update(user: user, preferences: email_preferences_params.to_h)

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
          UserServices::SMSSender.new(user: user).send_welcome_sms(user_params[:sms_code_password], 'regenerate') if user.saved_change_to_sms_code?
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
      @users = User.validated.where("avatar_key IS NOT NULL").order("updated_at DESC").page(params[:page]).per(25)
    end

    def edit_block
    end

    def block
      unless block_params[:cnil_explanation].present?
        redirect_to edit_block_admin_user_path(@user), flash: { error: "Merci de renseigner les raisons de cette action" } and return
      end

      @user.block! current_user, block_params[:cnil_explanation]
      redirect_to edit_admin_user_path(user), flash: { success: "Utilisateur bloqué" }
    end

    def temporary_block
      unless block_params[:cnil_explanation].present?
        redirect_to edit_block_admin_user_path(@user), flash: { error: "Merci de renseigner les raisons de cette action" } and return
      end

      @user.temporary_block! current_user, block_params[:cnil_explanation]
      redirect_to edit_admin_user_path(user), flash: { success: "Utilisateur bloqué pendant 1 mois" }
    end

    def unblock
      unless block_params[:cnil_explanation].present?
        redirect_to edit_block_admin_user_path(@user), flash: { error: "Merci de renseigner les raisons de cette action" } and return
      end

      @user.unblock! current_user, block_params[:cnil_explanation]
      redirect_to edit_admin_user_path(user), flash: { success: "Utilisateur débloqué" }
    end

    def cancel_phone_change_request
      if @user.pending_phone_change_request.present?
        UserServices::RequestPhoneChange.cancel_phone_change!(user: @user, admin: current_user)
        redirect_to [:admin, @user], flash: { success: "Demande de changement de téléphone annulée" }
      else
        redirect_to [:admin, @user], flash: { error: "L'utilisateur n'a pas de demande de changement de téléphone en cours" }
      end
    end

    def destroy_avatar
      UserServices::Avatar.new(user: user).destroy
      redirect_to edit_admin_user_path(user)
    end

    def banish
      @user.block! current_user, "banish"
      UserServices::Avatar.new(user: user).destroy
      redirect_to edit_admin_user_path(user)
    end

    def validate
      @user.validate!
      redirect_to moderate_admin_users_path
    end

    def experimental_pending_request_reminder
      reminders = @user.experimental_pending_request_reminders
      last_reminder_at = reminders.maximum(:created_at)
      reminders.create! if last_reminder_at.nil? || !last_reminder_at.today?
      redirect_back(fallback_location: root_path, flash: { _experimental_pending_request_reminder_created: 1 })
    end

    def download_export
      send_file UserServices::Exporter.new(user: @user).csv,
        filename: "users-personal-data-#{@user.phone.parameterize}.csv",
        type: "application/csv"
    end

    def send_export
      UserServices::Exporter.new(user: @user).export
      redirect_to [:admin, @user], flash: { success: "Export envoyé par mail (utilisateurs connectés depuis moins d'un an)" }
    end

    def download_list_export
      user_ids = filtered_users
        .where("last_sign_in_at > ?", LAST_SIGN_IN_AT_EXPORT)
        .order(last_sign_in_at: :desc)
        .pluck(:id).compact.uniq

      MemberMailer.users_csv_export(user_ids, current_user.email).deliver_later

      redirect_to admin_users_url(params: filter_params), flash: { success: "Vous recevrez l'export par mail (utilisateurs connectés depuis moins d'un an)" }
    end

    def anonymize
      @user.anonymize! current_user
      UserServices::Avatar.new(user: @user).destroy
      redirect_to [:admin, @user], flash: { success: "Utilisateur anonymisé" }
    end

    def new_spam_warning
      redirect_to [:admin, @user], flash: { success: "On ne peut prévenir du spam que sur un utilisateur bloqué" } unless @user.blocked?

      @chat_message = ChatMessage.new
    end

    def create_spam_warning
      redirect_to [:admin, @user], flash: {
        error: "On ne peut prévenir du spam que sur un utilisateur bloqué"
      } and return unless @user.blocked?

      redirect_to new_spam_warning_admin_user_path(@user), flash: {
        error: "Merci de renseigner un message"
      } and return unless params[:message].present?

      UserServices::SpamAlert.new(spammer: @user).alert!(current_user, params[:message]) do |on|
        on.success do |user|
          redirect_to [:admin, @user], flash: {
            success: "Un message est envoyé aux différents utilisateurs qui ont été en contact avec #{@user.full_name}"
          }
        end

        on.failure do |error, user|
          flash[:error] = "L'envoi n'a pas pu être effectué : #{error.message}"

          render :new_spam_warning
        end
      end
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
      params.require(:user).permit(:first_name, :last_name, :email, :sms_code_password, :phone, :lang, :travel_distance, :use_suggestions, :about, :accepts_emails, :targeting_profile, :partner_id, :admin, :moderator, :slack_id, :interest_list, interests: [])
    end

    def email_preferences_params
      params.permit(email_preferences: [:default, :newsletter, :unread_reminder, :digest_email])[:email_preferences] || {}
    end

    def block_params
      params.require(:user).permit(:cnil_explanation)
    end

    def moderation_params
      params.require(:user_moderation).permit(
        :skills, :expectations, :acquisition_channel
      )
    end

    def filter_params
      params.permit(:search, :profile, :engagement, :status, :role, q: {})
    end

    def filtered_users
      status = get_status
      role = get_role
      engagement = get_engagement
      profile = get_profile

      @users = current_user.community.users

      @users = @users.status_is(status)
      @users = @users.role_is(role)

      @users = @users.engaged if engagement == :engaged
      @users = @users.not_engaged if engagement == :not_engaged
      @users = @users.search_by(params[:search]) if params[:search].present?
      @users = @users.joins(:user_phone_changes).order('user_phone_changes.created_at') if status == :pending

      @users = @users.with_profile(profile.to_s) if profile.present?

      @users = @users.in_area("dep_" + params[:q][:postal_code_start]) if params[:q] && params[:q][:postal_code_start]
      @users = @users.in_area(:hors_zone) if params[:q] && params[:q][:postal_code_not_start_all]
      @users.group('users.id')
      @users
    end

    def get_profile
      profile = params[:profile].presence&.to_sym
      profile = :all unless profile.in?([:offer_help, :ask_for_help, :organization, :goal_not_known])
      profile
    end

    def get_engagement
      engagement = params[:engagement].presence&.to_sym
      engagement = :all unless engagement.in?([:engaged, :not_engaged])
      engagement
    end

    def get_status
      status = params[:status].presence&.to_sym
      status = :all unless status.in?([:blocked, :temporary_blocked, :deleted, :pending])
      status
    end

    def get_role
      role = params[:role].presence&.to_sym
      role = :all unless role.in?([:admin, :moderator])
      role
    end
  end

end
