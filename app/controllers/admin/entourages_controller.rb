module Admin
  class EntouragesController < Admin::BaseController
    EXPORT_PERIOD = 1.month

    before_action :set_entourage, only: [:show, :edit, :update, :close, :renew, :cancellation, :cancel, :edit_image, :update_image, :moderator_read, :moderator_unread, :message, :show_members, :show_joins, :show_invitations, :show_messages, :show_comments, :show_neighborhoods, :show_matchings, :show_siblings, :send_matching, :sensitive_words, :sensitive_words_check, :edit_type, :edit_owner, :update_owner, :update_neighborhoods]
    before_action :set_forced_join_request, only: [:message]

    before_action :set_default_index_params, only: [:index]
    before_action :set_index_params, only: [:index, :show, :edit, :show_messages, :show_members]

    def index
      per_page = params[:per] || 50

      @q = filtered_entourages

      @entourages = @q.result.page(params[:page]).per(per_page)
        .with_moderator_reads_for(user: current_user)
        .select(%(
          entourages.*,
          entourage_moderations.moderated_at is not null or entourages.created_at < '2018-01-01' as moderated,
          moderator_reads is null and entourages.created_at >= now() - interval '1 week' as unread,
          moderator_reads is null and entourages.created_at >= now() - interval '1 week' and has_image_url as unread_images
        ))
        .like(params[:search])
        .group("entourages.id, moderator_reads.id, entourage_moderations.id, entourage_denorms.id")
        .joins(%(left outer join entourage_denorms on entourage_denorms.entourage_id = entourages.id))
        .order(Arel.sql("case when status = 'open' then 1 else 2 end"))
        .order(Arel.sql(%(
          case
          when moderator_reads is null and entourages.created_at >= now() - interval '1 week' then 0
          when max(max_chat_message_created_at) >= moderator_reads.read_at then 1
          else 2
          end
        )))
        .order(Arel.sql(%(
          entourages.created_at DESC
        )))
        .to_a

      @entourages = Kaminari.paginate_array(@entourages, total_count: @q.result.count).page(params[:page]).per(per_page)

      entourage_ids = @entourages.map(&:id)

      @requests_count = JoinRequest
        .where(joinable_type: :Entourage, joinable_id: entourage_ids, status: :pending)
        .group(:joinable_id)
        .pluck(Arel.sql(%(
          joinable_id,
          count(*),
          count(case when updated_at <= now() - interval '48 hours' then 1 end)
        )))

      @requests_count = Hash[@requests_count.map { |id, total, late| [id, { total: total, late: late }]}]
      @requests_count.default = { total: 0, late: 0 }

      @reminded_users = Experimental::PendingRequestReminder.recent
        .where(user_id: @entourages.map(&:user_id))
        .pluck(Arel.sql('distinct user_id'))

      @reminded_users = Set.new(@reminded_users)

      @message_count = ConversationMessage
        .with_moderator_reads_for(user: current_user)
        .where(messageable_type: :Entourage, messageable_id: entourage_ids)
        .group(:messageable_id)
        .select(%{
          messageable_id,
          sum(case when conversation_messages.content <> '' then 1 else 0 end) as total,
          sum(case when conversation_messages.created_at >= moderator_reads.read_at then 1 else 0 end) as unread,
          sum(case when conversation_messages.created_at >= moderator_reads.read_at and conversation_messages.image_url is not null then 1 else 0 end) as unread_images
        })

      @message_count = Hash[@message_count.map { |m| [m.messageable_id, m] }]
      @message_count.default = OpenStruct.new(unread: 0, unread_images: 0, total: 0)
      @moderation = Hash[EntourageModeration.where(entourage_id: entourage_ids).pluck(:entourage_id, :moderated)]
      @moderation.default = false

      # workaround for the 'null' option
      @q = Entourage.ransack(params[:q])
    end

    def new
      @entourage = Entourage.new(
        group_type: params[:group_type].to_sym,
        public: true
      )

      render :edit
    end

    def create
      entourage_builder = EntourageServices::EntourageBuilder.new(params: entourage_params, user: current_user)
      entourage_builder.create do |on|
        on.success do |entourage|
          redirect_to edit_admin_entourage_path(entourage)
        end

        on.failure do |entourage|
          @entourage = entourage
          render :edit
        end
      end
    end

    def show
      @moderator_read = @entourage.moderator_read_for(user: current_user)
    end

    def show_members
      @moderator_read = @entourage.moderator_read_for(user: current_user)
      @requests = @entourage.join_requests
        .with_entourage_invitations
        .includes(:user)
        .to_a.find_all(&:is_accepted?)

      render :show
    end

    def show_messages
      @moderator_read  = @entourage.moderator_read_for(user: current_user)

      @join_requests = @entourage.join_requests
        .with_entourage_invitations
        .includes(:user)
        .to_a

      @chat_messages = @entourage.parent_conversation_messages.includes(:survey).order(created_at: :desc)
          .includes(:user)
          .with_content
          .page(params[:page])
          .per(params[:per])

      reads = @entourage.join_requests.accepted
        .reject { |r| r.last_message_read.nil? || r.user_id == current_user.id }
        .reject { |r| r.last_message_read < @chat_messages.first.created_at if @chat_messages.any? }
        .sort_by(&:last_message_read)

      @last_reads = Hash.new { |h, k| h[k] = [] }
      (@chat_messages + [nil]).each_cons(2) do |message, next_message|
        while reads.any? &&
              reads.first.last_message_read >= message.created_at &&
              (!next_message ||
               reads.first.last_message_read < next_message.created_at) do
          @last_reads[message.id].push reads.shift
        end
      end

      render :show
    end

    def show_comments
      @post = ChatMessage.find(params[:message_id])
      @comments = ChatMessage.find(params[:message_id]).children.order(created_at: :desc).page(page).per(per)

      render :show
    end

    def show_neighborhoods
      @outing = Outing.find(@entourage.id)
      @neighborhoods = @outing.neighborhoods.includes([:user])

      render :show
    end

    def show_matchings
      @action = Action.find(params[:id])
      @matchings = @action.matchings_with_notifications
        .select("matchings.*, max(inapp_notifications.created_at) AS inapp_notification_created_at")
        .group("matchings.id")
        .includes(:match)

      render :show
    end

    def show_siblings
      @outing = Outing.find(params[:id])
      @siblings = @outing.siblings

      render :show
    end

    def send_matching
      @matching = Matching.find(params[:matching_id])

      PushNotificationTrigger.new(@matching, :forced_create, Hash.new).run

      @matching.inapp_notification_created_at_virtual = @matching.inapp_notifications.pluck(:created_at).compact.max

      respond_to do |format|
        format.js
      end
    end

    def download_list_export
      entourage_ids = filtered_entourages.result.where(%((
        (group_type = 'outing' and metadata->>'starts_at' >= :starts_after) or
        (group_type = 'action' and created_at >= :created_after)
      )), {
        starts_after: EXPORT_PERIOD.ago,
        created_after: EXPORT_PERIOD.ago,
      }).pluck(:id).compact.uniq

      MemberMailer.entourages_csv_export(entourage_ids, current_user.email).deliver_later

      redirect_to admin_entourages_url(params: filter_params), flash: { success: "Vous recevrez l'export par mail (actions créées depuis moins d'un mois ou événements ayant eu lieu il y a moins d'un mois)" }
    end

    def stop_recurrences
      @outing = Outing.find(params[:id])
      @recurrence = @outing.recurrence

      return redirect_to show_siblings_admin_entourage_path(@outing), alert: "La récurrence n'a pas pu être identifiée" unless @recurrence

      if @recurrence.update_attribute(:continue, false)
        redirect_to show_siblings_admin_entourage_path(@outing), notice: "La récurrence a été annulée"
      else
        redirect_to show_siblings_admin_entourage_path(@outing), alert: "La récurrence n'a pas pu être annulée : #{@outing.errors.full_messages.to_sentence}"
      end
    end

    def moderator_read
      read_at =
        if params[:read_at]
          DateTime.parse(params[:read_at])
        else
          Time.zone.now
        end

      ModeratorReadsService
        .new(instance: @entourage, moderator: current_user)
        .mark_as_read(at: read_at)

      redirect_to show_messages_admin_entourage_path(@entourage)
    end

    def moderator_unread
      ModeratorReadsService
        .new(instance: @entourage, moderator: current_user)
        .mark_as_unread

      redirect_to show_messages_admin_entourage_path(@entourage)
    end

    def edit
    end

    def update
      update_params = entourage_params.to_h.with_indifferent_access

      if @entourage.group_type == 'outing' && params[:metadata].present?
        update_params[:metadata] ||= {}
        update_params[:metadata][:previous_at] = params[:metadata][:previous_at]
      end

      group_type_change = [
        @entourage.group_type&.to_sym,
        update_params[:group_type]&.to_sym
      ]
      group_type_change = nil if group_type_change.uniq.count == 1

      if group_type_change
        authorized_group_changes = [
          [:outing, :action],
          [:action, :outing],
          [:action, :group]
        ]
        raise unless group_type_change.in?(authorized_group_changes)

        @entourage.metadata = {}
      end

      if EntourageServices::EntourageBuilder.update(entourage: @entourage, params: update_params)
        Entourage.transaction do
          group_roles = {
            action: [:creator,   :member],
            outing: [:organizer, :participant],
            group:  [:admin,     :member]
          }
          role_changes = group_type_change.map { |type| group_roles[type] }.reduce(&:zip)
          role_changes.each do |old_role, new_role|
            @entourage.join_requests.where(role: old_role).update_all(role: new_role)
          end
        end if group_type_change

        redirect_to edit_admin_entourage_path(@entourage), notice: "Entourage mis à jour"
      else
        render :edit, alert: "Erreur lors de la mise à jour"
      end
    end

    def close
      if EntourageServices::EntourageBuilder.close(entourage: @entourage)
        redirect_to admin_entourage_path(@entourage), notice: "L'événement a été clôturé"
      else
        redirect_to admin_entourage_path(@entourage), alert: "L'événement n'a pas pu être clôturé : #{@entourage.errors.full_messages.to_sentence}"
      end
    end

    def renew
    end

    def cancellation
      redirect_to [:edit, :admin, @entourage], alert: "Seuls les événements peuvent être annulés" unless @entourage.outing?
    end

    def cancel
      if EntourageServices::EntourageBuilder.cancel(entourage: @entourage, params: cancel_params.to_h)
        redirect_to admin_entourage_path(@entourage), notice: "L'événement a été annulé"
      else
        redirect_to cancellation_admin_entourage_path(@entourage), alert: "L'événement n'a pas pu être annulé : #{@entourage.errors.full_messages.to_sentence}"
      end
    end

    def duplicate_outing
      original = Outing.find(params[:id])
      @outing = original.dup

      if @outing.save
        redirect_to admin_entourage_path(@outing), notice: "L'événement a été dupliqué"
      else
        redirect_to admin_entourage_path(@original), alert: "L'événement n'a pas été dupliqué: #{@outing.errors.full_messages.to_sentence}"
      end
    end

    def edit_image
      redirect_to edit_admin_entourage_path(@entourage) and return unless @entourage.outing?

      @entourage_images = EntourageImage.all
    end

    def update_image
      redirect_to edit_admin_entourage_path(@entourage) and return unless @entourage.outing?

      @entourage.assign_attributes(entourage_params)

      if @entourage.save
        redirect_to edit_admin_entourage_path(@entourage)
      else
        @entourage_images = EntourageImage.all
        render :edit_image
      end
    end

    def edit_type
      new_type = params[:to]&.to_sym
      current_type = @entourage.group_type.to_sym
      case [current_type, new_type]
      when [:action, :outing]
        @entourage.group_type = :outing
        @entourage.entourage_type = :contribution
        @entourage.display_category = :event
        @entourage.public = nil
        @entourage.metadata = {}
        @entourage.online = false
      when [:outing, :action]
        @entourage.group_type = :action
        @entourage.entourage_type = nil
        @entourage.display_category = nil
        @entourage.public = nil
        @entourage.metadata = {}
        @entourage.online = false
      else
        raise "Changing #{current_type} to #{new_type} is not allowed"
      end
    end

    def edit_owner
    end

    def update_owner
      user_id = entourage_params[:user_id]
      message = entourage_params[:change_ownership_message]

      EntourageServices::ChangeOwner.new(@entourage).to(user_id, message) do |success, error_message|
        if success
          redirect_to admin_entourage_path(@entourage), notice: "Mise à jour réussie"
        else
          redirect_to edit_owner_admin_entourage_path(@entourage), alert: error_message
        end
      end
    end

    def message
      ChatServices::ChatMessageBuilder.new(
        params: chat_messages_params,
        user: current_user,
        joinable: @entourage,
        join_request: @join_request
      ).create do |on|
        redirection = if chat_messages_params.has_key?(:parent_id)
          show_comments_admin_entourage_path(@entourage, message_id: chat_messages_params[:parent_id])
        else
          show_messages_admin_entourage_path(@entourage)
        end

        on.success do |message|
          @join_request.set_chat_messages_as_read_from(message.created_at)
          ModeratorReadsService
            .new(instance: @entourage, moderator: current_user)
            .mark_as_read

          redirect_to redirection
        end

        on.failure do |message|
          redirect_to redirection, alert: "Erreur lors de l'envoi du message : #{message.errors.full_messages.to_sentence}"
        end
      end
    end

    def destroy_message
      unless ['JoinRequest', 'ChatMessage'].include?(params[:type])
        return redirect_to admin_entourages_path, alert: "Wrong type param for destroy_message"
      end

      return destroy_join_request if params[:type] == 'JoinRequest'

      @chat_message = ChatMessage.find(params[:id])

      ChatServices::Deleter.new(user: current_user, chat_message: @chat_message).delete(true) do |on|
        redirection = if @chat_message.has_parent?
          show_comments_admin_entourage_path(@chat_message.messageable_id, message_id: @chat_message.parent_id)
        else
          show_messages_admin_entourage_path(@chat_message.messageable)
        end

        on.success do |chat_message|
          redirect_to redirection
        end

        on.failure do |chat_message|
          redirect_to redirection, alert: chat_message.errors.full_messages
        end

        on.not_authorized do
          redirect_to redirection, alert: "You are not authorized to delete this chat_message"
        end
      end
    end

    def destroy_join_request
      join_request = JoinRequest.find(params[:id])
      join_request.message = nil
      join_request.save

      redirect_to [:admin, join_request.joinable]
    end

    def sensitive_words
      highlighted = SensitiveWordsService.highlight_entourage @entourage
      @title = highlighted[:title]
      @description = highlighted[:description]
      @matches = highlighted[:matches]
    end

    def sensitive_words_check
      check = @entourage.sensitive_words_check || @entourage.build_sensitive_words_check
      check.status = params[:status]
      check.save!
      redirect_to admin_entourage_path(@entourage)
    end

    def update_neighborhoods
      unless @entourage.outing?
        return redirect_to show_neighborhoods_admin_entourage_path(@entourage), alert: "Seuls les événements peuvent être associés à des groupes de voisins"
      end

      @outing = Outing.find(@entourage.id)
      @outing.assign_attributes(outing_neighborhoods_param)

      if @outing.save(validate: false) # we do not want validation on starts_at or neighborhood_ids memberships
        redirect_to show_neighborhoods_admin_entourage_path(@outing), notice: "Votre modification a bien été prise en compte"
      else
        redirect_to show_neighborhoods_admin_entourage_path(@outing), alert: "Votre modification n'a pas pu être prise en compte"
      end
    end

    private

    def per
      params[:per] || 25
    end

    def page
      params[:page] || 1
    end

    def set_entourage
      @entourage = Entourage.find(params[:id])

      if @entourage.outing?
        @entourage = Outing.find(params[:id])
      end
    end

    def set_forced_join_request
      @join_request = current_user.join_requests.find_by(joinable: @entourage)

      return if @join_request.present? && @join_request.accepted?

      if @join_request.present?
        @join_request.status = :accepted
      else
        role = @entourage.action? ? :member : :participant
        @join_request = JoinRequest.new(joinable: @entourage, user: current_user, role: role, status: :accepted)
      end

      @join_request.save!
    end

    def set_index_params
      @params = index_params
    end

    def set_default_index_params
      # set default moderator_id
      main_moderator = ModerationServices.moderator_if_exists(community: :entourage)

      if current_user != main_moderator && (params.keys - ['controller', 'action']).none? && current_user.roles.include?(:moderator)
        params[:moderator_id] = current_user.id
      end

      params[:moderator_id] = 'any' unless params[:moderator_id].present?

      # set default status_in
      return if params[:q] && params[:q][:status_in].present?

      params[:q] ||= {}
      params[:q][:status_in] = ['open', 'suspended', 'full', 'blacklisted', 'closed', 'full', 'cancelled']
    end

    def index_params
      params.permit([:search, :moderator_id, q: [:entourage_type_eq, :status_in, :display_category_eq, :country_eq, :postal_code_start, :group_type_eq, :moderation_action_outcome_blank, :created_at_lt, postal_code_start_any: [], postal_code_not_start_all: []]]).to_h
    end

    def entourage_params
      metadata_keys = params.dig(:entourage, :metadata).try(:keys) || [] # security issue
      metadata_keys -= [:starts_at]
      permitted = params.require(:entourage).permit(:group_type, :status, :title, :description, :category, :entourage_type, :display_category, :latitude, :longitude, :public, :online, :url, :event_url, :user_id, :entourage_image_id, :change_ownership_message, :sf_category, metadata: metadata_keys)

      [:starts_at, :ends_at].each do |timestamp|
        datetime = params.dig(:entourage, :metadata, timestamp)&.slice(:date, :hour, :min)
        if datetime.present?
          permitted[:metadata] ||= {}
          permitted[:metadata][timestamp] = Date.strptime(datetime[:date]).in_time_zone.change(
            hour: datetime[:hour],
            min:  datetime[:min]
          )
        end
      end

      permitted
    end

    def cancel_params
      params.require(:entourage).permit(:cancellation_message)
    end

    def chat_messages_params
      params.require(:chat_message).permit(:content, :parent_id)
    end

    def outing_neighborhoods_param
      params.require(:outing).permit(neighborhood_ids: [])
    end

    def filter_params
      params.permit(:search, :moderator_id, :group_type, q: {})
    end

    def filtered_entourages
      # workaround for the 'null' option
      if params.dig(:q, :display_category_eq) == EntouragesHelper::NO_CATEGORY
        ransack_params = params[:q].dup
        ransack_params.delete(:display_category_eq)
        ransack_params.merge!(display_category_null: 1)
      else
        ransack_params = params[:q]
      end

      group_types = (params[:group_type] || 'action,outing').split(',')

      Entourage.where(group_type: group_types).like(params[:search]).with_moderation
        .moderator_search(params[:moderator_id])
        .ransack(ransack_params)
    end
  end
end
