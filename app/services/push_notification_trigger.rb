class PushNotificationTrigger
  # observed by PushNotificationTriggerObserver:
  #  :entourage
  #  :entourage_moderation
  #  :chat_message
  #  :join_request
  #  :neighborhoods_entourage
  #  :matching

  I18nStruct = Struct.new(:i18n, :i18n_args, :instance, :field, :date, :text) do
    def initialize(i18n: nil, i18n_args: [], instance: nil, field: nil, date: nil, text: nil)
      @i18ns = Hash.new # memorizes translations

      @i18n = i18n
      @i18n_args = i18n_args
      @instance = instance
      @field = field
      @date = date
      @text = text
    end

    def to lang
      return @i18ns[lang] if @i18ns.has_key?(lang)

      return @i18ns[lang] = I18n.l(@date, locale: lang, format: :long).strip if @date.present?
      return @i18ns[lang] = I18n.t(@i18n, locale: lang) % args_to(lang) if @i18n.present?

      if @instance.present? && @field.present?
        return @i18ns[lang] = @instance.send(@field) unless @instance.respond_to?(:translation) && @instance.translation.present?
        return @i18ns[lang] = @instance.translation.translate(field: @field, lang: lang) || @instance.send(@field)
      end

      @i18ns[lang] = @text % args_to(lang)
      @i18ns[lang]
    end

    # handle translatable arguments
    def args_to lang
      @i18n_args.map do |i18n_arg|
        if i18n_arg.is_a?(I18nStruct)
          i18n_arg.to(lang)
        else
          i18n_arg
        end
      end
    end
  end

  DISTANCE_OF_ACTION = 10

  attr_reader :record, :method, :changes

  # @param verb Either :create, :update or :destroy. "day_before" has been added
  def initialize record, verb, changes
    @record = record
    @method = "#{record.class.name.underscore}_on_#{verb.to_s}".to_sym
    @changes = changes
  end

  def run
    return unless respond_to?(@method)

    send(@method)
  rescue => e
    Rails.logger.error "PushNotificationTrigger: #{e.message}"
  end

  def neighborhoods_entourage_on_create
    neighborhood = @record.neighborhood
    entourage = @record.entourage

    return unless entourage.outing?
    return unless entourage.moderation_validated?
    return unless entourage.first_occurrence?
    return unless (user_ids = neighborhood.member_ids.uniq - [entourage.user_id]).any?

    User.where(id: user_ids).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: entourage.user_id,
        referent: neighborhood,
        instance: entourage,
        users: batches,
        params: {
          object: I18nStruct.new(instance: neighborhood, field: :name),
          content: I18nStruct.new(
            i18n: 'push_notifications.outing.create',
            i18n_args: [entity_name(neighborhood), title(entourage), to_date(entourage.starts_at)
            ]),
          extra: {
            tracking: :outing_on_add_to_neighborhood
          }
        }
      )
    end
  end

  def entourage_moderation_on_create
    return entourage_moderation_on_update_validated_at if @changes.keys.include?("validated_at")
  end

  def entourage_moderation_on_update
    return entourage_moderation_on_update_validated_at if @changes.keys.include?("validated_at")
  end

  def entourage_moderation_on_update_validated_at
    record = @record

    return unless record.validated_at.present?
    return unless record.entourage.present?
    return unless record.entourage.action? || record.entourage.outing?
    return unless record.entourage.ongoing?

    async_entourage_on_create(record.entourage)
    async_neighborhoods_entourage_on_create(record.entourage)
  end

  def async_entourage_on_create entourage
    # configure entourage_on_create
    @record = entourage
    @method = "entourage_on_create"
    @changes = {}

    return unless @record.outing? || @record.action?
    return unless user = @record.user

    entourage_on_create_for_followers(user)
    entourage_on_create_for_neighbors(user) if @record.action?
  end

  def async_neighborhoods_entourage_on_create entourage
    # configure neighborhoods_entourage_on_create
    @method = "neighborhoods_entourage_on_create"
    @changes = {}

    return unless entourage.outing?

    NeighborhoodsEntourage.where(entourage_id: entourage.id).each do |neighborhood_entourage|
      @record = neighborhood_entourage

      neighborhoods_entourage_on_create
    end
  end

  def entourage_on_create_for_followers user
    return unless partner = user.partner

    follower_ids = Following.where(partner: partner, active: true).pluck(:user_id)

    return unless follower_ids.any?

    tracking = if @record.outing?
      :outing_on_create
    elsif @record.contribution?
      :contribution_on_create
    else
      :solicitation_on_create
    end

    User.where(id: follower_ids).where.not(id: user.id).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: @record.user_id,
        referent: @record,
        instance: @record,
        users: batches,
        params: {
          object: I18nStruct.new(instance: @record, field: :title),
          content: I18nStruct.new(i18n: 'push_notifications.action.create_for_follower', i18n_args: [partner.name, title(@record)]),
          extra: {
            tracking: tracking,
            type: "ENTOURAGE_INVITATION",
            entourage_id: @record.id,
            group_type: @record.group_type,
            inviter_id: nil,
            invitee_id: nil,
            invitation_id: nil
          }
        }
      )
    end
  end

  # initial caller: entourage_on_create
  def entourage_on_create_for_neighbors user
    return unless @record.action?

    neighbor_ids = Address.inside_perimeter(@record.latitude, @record.longitude, DISTANCE_OF_ACTION).pluck(:user_id).compact.uniq
    neighbor_ids = User.where(id: neighbor_ids)
      .where(deleted: false)
      .where.not(id: user.id)
      .where("last_sign_in_at > ?", 1.year.ago)

    neighbor_ids = neighbor_ids.offer_help.pluck(:id) if @record.solicitation?
    neighbor_ids = neighbor_ids.ask_for_help.pluck(:id) if @record.contribution?

    return unless neighbor_ids.any?

    tracking = @record.contribution? ? :contribution_on_create : :solicitation_on_create

    User.where(id: neighbor_ids).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: @record.user_id,
        referent: @record,
        instance: @record,
        users: batches,
        params: {
          object: content_for_create_action(@record),
          content: I18nStruct.new(instance: @record, field: :title),
          extra: {
            tracking: tracking,
            type: "ENTOURAGE_INVITATION",
            entourage_id: @record.id,
            group_type: @record.group_type
          }
        }
      )
    end
  end

  def entourage_on_update
    return if @record.blacklisted?
    return unless @record.moderation_validated?

    return outing_on_update if @record.outing?
  end

  # initial caller: entourage_on_update
  def outing_on_update
    return outing_on_update_status if @changes.keys.include?("status")
    return unless @changes.any? # it happens when neighborhoods_entourage is updated

    return unless (@changes.keys & ["latitude", "longitude", "postal_code", "country"]).any? || outing_metadata_changes(@changes["metadata"]).any?

    return unless (user_ids = @record.accepted_member_ids.uniq - [@record.user_id]).any?

    User.where(id: user_ids).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: @record.user_id,
        referent: @record,
        instance: @record,
        users: batches,
        params: {
          object: I18nStruct.new(instance: @record, field: :title),
          content: update_outing_message(@record, @changes),
          extra: {
            tracking: :outing_on_update
          }
        }
      )
    end
  end

  # initial caller: entourage_on_update
  def outing_on_update_status
    return outing_on_cancel if @record.cancelled?
    return outing_on_cancel if @record.closed? && @record.future_outing?

    # future notifications on other status?
  end

  def outing_on_cancel
    return unless (user_ids = @record.accepted_member_ids.uniq - [@record.user_id]).any?

    User.where(id: user_ids).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: @record.user_id,
        referent: @record,
        instance: @record,
        users: batches,
        params: {
          object: I18nStruct.new(instance: @record, field: :title),
          content: I18nStruct.new(i18n: 'push_notifications.outing.cancel', i18n_args: [to_date(@record.starts_at)]),
          extra: {
            tracking: :outing_on_cancel
          }
        }
      )
    end
  end

  def outing_on_day_before
    return if @record.place_limit?

    users = @record.accepted_members - [@record.user]

    return if users.none?

    notify(
      sender_id: @record.user_id,
      referent: @record,
      instance: @record,
      users: users,
      params: {
        object: I18nStruct.new(i18n: 'push_notifications.outing.day_before.title', i18n_args: [title(@record)]),
        content: I18nStruct.new(i18n: 'push_notifications.outing.day_before.content'),
        extra: {
          tracking: :outing_on_day_before,
          popup: :outing_on_day_before
        }
      }
    )
  end

  def chat_message_on_create
    return unless ['text', 'broadcast'].include? @record.message_type

    return comment_on_create if @record.has_parent?
    return post_on_create if @record.messageable.is_a?(Neighborhood)
    return post_on_create if @record.messageable.respond_to?(:outing?) && @record.messageable.outing?
    return public_chat_message_on_create if @record.messageable.respond_to?(:action?) && @record.messageable.action?

    private_chat_message_on_create
  end

  # initial caller: chat_message_on_create
  def public_chat_message_on_create
    return unless (user_ids = @record.messageable.accepted_member_ids.uniq - [@record.user_id]).any?

    User.where(id: user_ids).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: @record.user_id,
        referent: @record.messageable,
        instance: @record,
        users: batches,
        params: {
          object: I18nStruct.new(text: "#{username(@record.user)} - %s", i18n_args: [title(@record.messageable)]), # @requires i18n
          content: I18nStruct.new(instance: @record, field: :content),
          extra: {
            tracking: :public_chat_message_on_create,
            group_type: group_type(@record.messageable),
            joinable_id: @record.messageable_id,
            joinable_type: @record.messageable_type,
            type: "NEW_CHAT_MESSAGE"
          }
        }
      )
    end
  end

  # initial caller: chat_message_on_create
  def private_chat_message_on_create
    return unless (user_ids = @record.messageable.accepted_member_ids.uniq - [@record.user_id]).any?

    User.where(id: user_ids).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: @record.user_id,
        referent: @record.messageable,
        instance: @record.messageable,
        users: batches,
        params: {
          object: I18nStruct.new(text: username(@record.user)),
          content: I18nStruct.new(instance: @record, field: :content),
          extra: {
            tracking: :private_chat_message_on_create,
            group_type: group_type(@record.messageable),
            joinable_id: @record.messageable_id,
            joinable_type: @record.messageable_type,
            type: "NEW_CHAT_MESSAGE"
          }
        }
      )
    end
  end

  # initial caller: chat_message_on_create
  def post_on_create
    return unless (user_ids = @record.messageable.accepted_member_ids.uniq - [@record.user_id]).any?

    tracking = if @record.messageable.is_a?(Neighborhood)
      :post_on_create_to_neighborhood
    elsif @record.messageable.respond_to?(:outing?) && @record.messageable.outing?
      :post_on_create_to_outing
    else
      :post_on_create
    end

    User.where(id: user_ids).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: @record.user_id,
        referent: @record.messageable,
        instance: @record.messageable,
        users: batches,
        params: {
          object: title(@record.messageable),
          content: I18nStruct.new(i18n: 'push_notifications.post.create', i18n_args: [username(@record.user), content(@record)]),
          extra: {
            tracking: tracking,
            group_type: group_type(@record.messageable),
            joinable_id: @record.messageable_id,
            joinable_type: @record.messageable_type,
            type: "NEW_CHAT_MESSAGE"
          }
        }
      )
    end
  end

  # initial caller: chat_message_on_create
  def comment_on_create
    return unless @record.has_parent?

    user_ids = @record.siblings.pluck(:user_id).uniq + [@record.parent.user_id] - [@record.user_id]

    return unless user_ids.any?

    tracking = if @record.messageable.is_a?(Neighborhood)
      :comment_on_create_to_neighborhood
    elsif @record.messageable.respond_to?(:outing?) && @record.messageable.outing?
      :comment_on_create_to_outing
    else
      :comment_on_create
    end

    User.where(id: user_ids).find_in_batches(batch_size: 100) do |batches|
      # should redirect to post
      notify(
        sender_id: @record.user_id,
        referent: @record.messageable,
        instance: @record.parent,
        users: batches,
        params: {
          object: title(@record.messageable),
          content: I18nStruct.new(i18n: 'push_notifications.comment.create', i18n_args: [username(@record.user), content(@record)]),
          extra: {
            tracking: tracking
          }
        }
      )
    end
  end

  def chat_message_on_mention
    return unless @record.respond_to?(:mentions)
    return unless @record.mentions.respond_to?(:extract_user_uuid)

    user_ids = User.where(uuid: @record.mentions.extract_user_uuid).pluck(:id).uniq

    return unless user_ids.any?

    puts "-- push to: #{user_ids}"

    User.where(id: user_ids).find_in_batches(batch_size: 100) do |batches|
      notify(
        sender_id: @record.user_id,
        referent: @record.messageable,
        instance: @record.messageable,
        users: batches,
        params: {
          object: I18nStruct.new(i18n: 'push_notifications.chat_message.mention', i18n_args: [username(@record.user)]),
          content: I18nStruct.new(instance: @record, field: :content),
          extra: {
            tracking: :chat_message_on_mention
          }
        }
      )
    end
  end

  def user_reaction_on_create
    return unless @record.respond_to?(:instance)
    return unless @record.instance.respond_to?(:user_id)

    author_id = @record.instance.user_id

    return if author_id == @record.user_id

    notify(
      sender_id: @record.user_id,
      referent: @record.instance.messageable,
      instance: @record.instance.messageable,
      users: [@record.instance.user],
      params: {
        object: title(@record.instance.messageable),
        content: I18nStruct.new(i18n: 'push_notifications.reaction.create', i18n_args: [username(@record.user), content(@record.instance)]),
        extra: {
          tracking: :reaction_on_create
        }
      }
    )
  end

  def join_request_on_create
    return unless @record.accepted?
    return if @record.joinable.is_a?(Entourage) && @record.joinable.conversation?
    return if @record.joinable && @record.joinable.user == @record.user

    content = if @record.joinable.is_a?(Entourage) && @record.joinable.outing?
      I18nStruct.new(i18n: 'push_notifications.join_request.create_outing', i18n_args: [username(@record.user), title(@record.joinable), to_date(@record.joinable.starts_at)])
    else
      I18nStruct.new(i18n: 'push_notifications.join_request.create', i18n_args: [username(@record.user), entity_name(@record.joinable), title(@record.joinable)])
    end

    tracking = if @record.joinable.is_a?(Neighborhood)
      :join_request_on_create_to_neighborhood
    elsif @record.joinable.respond_to?(:outing?) && @record.joinable.outing?
      :join_request_on_create_to_outing
    else
      :join_request_on_create
    end

    notify(
      sender_id: @record.user_id,
      referent: @record.joinable,
      instance: @record.user,
      users: @record.joinable.creators_or_organizers.to_a,
      params: {
        object: I18nStruct.new(i18n: 'push_notifications.join_request.new'),
        content: content,
        extra: {
          tracking: tracking,
          joinable_id: @record.joinable_id,
          joinable_type: @record.joinable_type,
          group_type: group_type(@record.joinable),
          type: "JOIN_REQUEST_ACCEPTED",
          user_id: @record.user_id
        }
      }
    )
  end

  def join_request_on_update
    return unless @changes.keys.include?("status")
    return join_request_on_create unless @changes["status"] && @changes["status"].first&.to_sym == :pending

    content_key = "push_notifications.join_request.update_on_#{@record.joinable.group_type}"

    notify(
      sender_id: @record.user_id,
      referent: @record.joinable,
      instance: @record.joinable,
      users: [@record.user],
      params: {
        object: title(@record.joinable) || I18nStruct.new(i18n: 'push_notifications.join_request.update'),
        content: I18nStruct.new(i18n: content_key, i18n_args: [username(@record.joinable.user)]),
        extra: {
          joinable_id: @record.joinable_id,
          joinable_type: @record.joinable_type,
          group_type: group_type(@record.joinable),
          type: "JOIN_REQUEST_ACCEPTED",
          user_id: @record.user_id
        }
      }
    )
  end

  def survey_response_on_create
    return unless @record.chat_message.present?

    return if @record.chat_message.user_id == @record.user_id

    notify(
      sender_id: @record.user_id,
      referent: @record.chat_message.messageable,
      instance: @record.chat_message.messageable,
      users: [@record.chat_message.user],
      params: {
        object: title(@record.chat_message.messageable),
        content: I18nStruct.new(i18n: 'push_notifications.survey_response.create', i18n_args: [username(@record.user), I18nStruct.new(instance: @record.chat_message, field: :content)]),
        extra: {
          tracking: :survey_response_on_create,
        }
      }
    )
  end

  def matching_on_create
    return unless @record.position <= 1

    matching_on_forced_create
  end

  def matching_on_forced_create
    return unless instance = @record.instance
    return unless match = @record.match
    return unless moderator_id = ModerationServices.moderator_for_user(instance.user)&.id || match&.user_id

    notify(
      sender_id: moderator_id,
      referent: match,
      instance: match,
      users: [instance.user],
      params: {
        object: I18nStruct.new(i18n: 'push_notifications.matching.create'),
        content: I18nStruct.new(instance: match, field: :name),
        extra: {
          tracking: :matching
        }
      }
    )
  end

  # use params[:extra] to be compliant with v7
  def notify sender_id:, referent:, instance:, users:, params: {}
    notify_push(sender_id: sender_id, referent: referent, instance: instance, users: users, params: params)
    notify_inapp(sender_id: sender_id, referent: referent, instance: instance, users: users, params: params)
  end

  def notify_push sender_id:, referent:, instance:, users:, params: {}
    instance = PushNotificationLinker.get(instance)
    referent = PushNotificationLinker.get(referent)

    PushNotificationService.new.send_notification(
      params[:sender],
      params[:object],
      params[:content],
      users,
      referent[:instance],
      referent[:instance_id],
      instance.merge(params[:extra] || {}).merge(params[:options] || {})
    )
  end

  def notify_inapp sender_id:, referent:, instance:, users:, params: {}
    instance = PushNotificationLinker.get(instance)
    referent = PushNotificationLinker.get(referent)

    return unless instance.any?

    users.map do |user|
      InappNotificationServices::Builder.new(user).instanciate(
        context: @method,
        sender_id: sender_id,
        instance: instance[:instance],
        instance_id: instance[:instance_id],
        post_id: instance[:post_id],
        referent: referent[:instance],
        referent_id: referent[:instance_id],
        title: params[:object].to(user.lang),
        content: params[:content].to(user.lang),
        options: params[:options] || Hash.new
      )
    end
  end

  def username user
    UserPresenter.new(user: user).display_name
  end

  def title object
    return unless object.respond_to?(:title)
    return if object.respond_to?(:conversation?) && object.conversation?

    I18nStruct.new(instance: object, field: :title)
  end

  def group_type object
    return unless object.respond_to?(:group_type)

    object.group_type
  end

  def entity_name object
    GroupService.name object
  end

  def content chat_message
    I18nStruct.new(instance: chat_message, field: :content)
  end

  def content_for_create_action object
    return unless object.is_a?(Entourage)
    return unless object.action?

    return I18nStruct.new(i18n: 'push_notifications.contribution.create') if object.contribution?
    return I18nStruct.new(i18n: 'push_notifications.solicitation.create') unless section = Solicitation.find(object.id).section

    I18nStruct.new(i18n: 'push_notifications.solicitation.create_section', i18n_args: [I18n.t("tags.sections.#{section}.name").downcase])
  end

  def to_date date_str
    return unless date_str

    I18nStruct.new(date: date_str.to_date)
  end

  def outing_metadata_changes metadata_changes
    return [] unless metadata_changes
    return [] unless metadata_changes.size == 2

    metadata_changes.first.slice("starts_at", "ends_at").to_a - metadata_changes.last.slice("starts_at", "ends_at").to_a
  end

  def update_outing_message outing, changes
    metadata_before_last_save = changes["metadata"] ? changes["metadata"].first : {}

    if metadata_before_last_save.keys.include?("starts_at") && metadata_before_last_save.keys.include?("display_address")
      return I18nStruct.new(i18n: 'push_notifications.outing.update', i18n_args: [
        to_date(metadata_before_last_save["starts_at"] || outing.starts_at),
        to_date(outing.starts_at),
        outing.metadata["display_address"] || outing.metadata[:display_address]
      ])
    end

    I18nStruct.new(i18n: 'push_notifications.outing.update_short', i18n_args: [to_date(outing.starts_at)])
  end
end
