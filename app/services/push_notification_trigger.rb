class PushNotificationTrigger
  # observed by PushNotificationTriggerObserver:
  #  :entourage
  #  :entourage_moderation
  #  :chat_message
  #  :join_request
  #  :neighborhoods_entourage

  CREATE_OUTING = "Un nouvel événement vient d'être ajouté au %s : %s prévu le %s"
  CANCEL_OUTING = "Cet événement prévu le %s vient d'être annulé"
  UPDATE_OUTING = "L'événement prévu le %s a été modifié. Il se déroulera le %s, au %s"
  UPDATE_OUTING_SHORT = "L'événement prévu le %s a été modifié"
  CREATE_POST = "%s vient de partager : \"%s\""
  CREATE_COMMENT = "%s vient de commenter la publication \"%s\""
  CREATE_JOIN_REQUEST = "%s vient de rejoindre votre %s \"%s\""
  CREATE_JOIN_REQUEST_OUTING = "%s vient de rejoindre votre événement \"%s\" du %s"
  CREATE_CONTRIBUTION = "Un voisin propose une nouvelle entraide"
  CREATE_SOLICITATION = "Un voisin recherche une aide"
  CREATE_SOLICITATION_SECTION = "Un voisin recherche un %s"

  DISTANCE_OF_ACTION = 10

  attr_reader :record, :method, :changes

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
    return unless users = (neighborhood.members.uniq - [entourage.user])

    notify(
      sender_id: entourage.user_id,
      referent: neighborhood,
      instance: entourage,
      users: users,
      params: {
        object: neighborhood.title,
        content: CREATE_OUTING % [entity_name(neighborhood), entourage.title, to_date(entourage.starts_at)],
        extra: {
          tracking: :outing_on_add_to_neighborhood
        }
      }
    )
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

    follower_ids.each do |follower_id|
      next if follower_id == user.id
      next unless follower = User.find(follower_id)

      invitation_id = EntourageInvitation.where(invitable: @record, inviter: user, invitee_id: follower_id).pluck(:id).first

      notify(
        sender_id: @record.user_id,
        referent: @record,
        instance: @record,
        users: [follower],
        params: {
          object: @record.title,
          content: "#{partner.name} vous invite à rejoindre #{title(@record)}",
          extra: {
            tracking: tracking,
            type: "ENTOURAGE_INVITATION",
            entourage_id: @record.id,
            group_type: @record.group_type,
            inviter_id: user.id,
            invitee_id: follower_id,
            invitation_id: invitation_id
          }
        }
      )
    end
  end

  # initial caller: entourage_on_create
  def entourage_on_create_for_neighbors user
    return unless @record.action?

    neighbor_ids = Address.inside_perimeter(@record.latitude, @record.longitude, DISTANCE_OF_ACTION).pluck(:user_id).compact.uniq

    return unless neighbor_ids.any?

    tracking = @record.contribution? ? :contribution_on_create : :solicitation_on_create

    neighbor_ids.each do |neighbor_id|
      next if neighbor_id == user.id
      next unless neighbor = User.find(neighbor_id)
      next if neighbor.deleted?
      next if neighbor.community == :pfp

      next if @record.solicitation? && neighbor.is_ask_for_help?
      next if @record.contribution? && !neighbor.is_ask_for_help?

      notify(
        sender_id: @record.user_id,
        referent: @record,
        instance: @record,
        users: [neighbor],
        params: {
          object: content_for_create_action(@record),
          content: @record.title,
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

    users = @record.accepted_members - [@record.user]

    return if users.none?

    notify(
      sender_id: @record.user_id,
      referent: @record,
      instance: @record,
      users: users,
      params: {
        object: @record.title,
        content: update_outing_message(@record, @changes),
        extra: {
          tracking: :outing_on_update
        }
      }
    )
  end

  # initial caller: entourage_on_update
  def outing_on_update_status
    return outing_on_cancel if @record.cancelled?
    return outing_on_cancel if @record.closed? && @record.future_outing?

    # future notifications on other status?
  end

  def outing_on_cancel
    users = @record.accepted_members - [@record.user]

    return if users.none?

    notify(
      sender_id: @record.user_id,
      referent: @record,
      instance: @record,
      users: users,
      params: {
        object: @record.title,
        content: CANCEL_OUTING % to_date(@record.starts_at),
        extra: {
          tracking: :outing_on_cancel
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
    users = @record.messageable.accepted_members - [@record.user]

    return if users.none?

    notify(
      sender_id: @record.user_id,
      referent: @record.messageable,
      instance: @record,
      users: users,
      params: {
        object: "#{username(@record.user)} - #{title(@record.messageable)}",
        content: @record.content,
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

  # initial caller: chat_message_on_create
  def private_chat_message_on_create
    users = @record.messageable.accepted_members - [@record.user]

    return if users.none?

    notify(
      sender_id: @record.user_id,
      referent: @record.messageable,
      instance: @record.messageable,
      users: users,
      params: {
        object: username(@record.user),
        content: @record.content,
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

  # initial caller: chat_message_on_create
  def post_on_create
    users = @record.messageable.accepted_members - [@record.user]

    return if users.none?

    tracking = if @record.messageable.is_a?(Neighborhood)
      :post_on_create_to_neighborhood
    elsif @record.messageable.respond_to?(:outing?) && @record.messageable.outing?
      :post_on_create_to_outing
    else
      :post_on_create
    end

    notify(
      sender_id: @record.user_id,
      referent: @record.messageable,
      instance: @record.messageable,
      users: users,
      params: {
        object: title(@record.messageable),
        content: CREATE_POST % [username(@record.user), @record.content],
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

    # should redirect to post
    notify(
      sender_id: @record.user_id,
      referent: @record.messageable,
      instance: @record.parent,
      users: User.where(id: user_ids),
      params: {
        object: title(@record.messageable),
        content: CREATE_COMMENT % [username(@record.user), @record.content],
        extra: {
          tracking: tracking
        }
      }
    )
  end

  def join_request_on_create
    return unless @record.accepted?
    return if @record.joinable.is_a?(Entourage) && @record.joinable.conversation?
    return if @record.joinable && @record.joinable.user == @record.user

    content = if @record.joinable.is_a?(Entourage) && @record.joinable.outing?
      CREATE_JOIN_REQUEST_OUTING % [username(@record.user), title(@record.joinable), to_date(@record.joinable.starts_at)]
    else
      CREATE_JOIN_REQUEST % [username(@record.user), entity_name(@record.joinable), title(@record.joinable)]
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
      users: [@record.joinable.user],
      params: {
        object: "Nouveau membre",
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

    notify(
      sender_id: @record.user_id,
      referent: @record.joinable,
      instance: @record.joinable,
      users: [@record.user],
      params: {
        object: title(@record.joinable) || "Demande acceptée",
        content: "Vous venez de rejoindre un(e) #{entity_name(@record.joinable)} de #{username(@record.joinable.user)}",
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
        title: params[:object],
        content: params[:content],
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

    object.title
  end

  def group_type object
    return unless object.respond_to?(:group_type)

    object.group_type
  end

  def entity_name object
    GroupService.name object
  end

  def content_for_create_action object
    return unless object.is_a?(Entourage)
    return unless object.action?

    return CREATE_CONTRIBUTION if object.contribution?
    return CREATE_SOLICITATION unless section = Solicitation.find(object.id).section

    CREATE_SOLICITATION_SECTION % I18n.t("tags.sections.#{section}.name", default: CREATE_SOLICITATION).downcase
  end

  def to_date date_str
    return unless date_str

    I18n.l(date_str.to_date)
  end

  def update_outing_message outing, changes
    metadata_before_last_save = changes["metadata"] ? changes["metadata"].first : {}

    if metadata_before_last_save.keys.include?("starts_at") && metadata_before_last_save.keys.include?("display_address")
      return UPDATE_OUTING % [
        to_date(metadata_before_last_save["starts_at"] || outing.starts_at),
        to_date(outing.starts_at),
        outing.metadata["display_address"] || outing.metadata[:display_address]
      ]
    end

    UPDATE_OUTING_SHORT % to_date(outing.starts_at)
  end
end
