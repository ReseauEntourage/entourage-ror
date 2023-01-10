class PushNotificationTrigger
  CREATE_OUTING = "Un nouvel événement vient d'être ajouté au %s : %s prévu le %s"
  CANCEL_OUTING = "Cet événement prévu le %s vient d'être annulé"
  UPDATE_OUTING = "L'événement prévu le %s a été modifié. Il se déroulera le %s, au %s"
  UPDATE_OUTING_SHORT = "L'événement prévu le %s a été modifié"
  CREATE_POST = "%s vient de partager : \"%s\""
  CREATE_COMMENT = "%s vient de commenter la publication \"%s\""
  CREATE_JOIN_REQUEST = "%s vient de rejoindre votre %s \"%s\""
  CREATE_JOIN_REQUEST_OUTING = "%s vient de rejoindre votre événement \"%s\" du %s"

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
    return unless users = (neighborhood.members.uniq - [entourage.user])

    notify(
      referent: neighborhood,
      instance: entourage,
      users: users,
      params: {
        object: neighborhood.title,
        content: CREATE_OUTING % [entity_name(neighborhood), entourage.title, to_date(entourage.starts_at)]
      }
    )
  end

  def entourage_on_create
    return unless @record.outing? || @record.action?
    return unless user = @record.user
    return unless partner = user.partner

    follower_ids = Following.where(partner: partner, active: true).pluck(:user_id)

    return unless follower_ids.any?

    follower_ids.each do |follower_id|
      next unless follower = User.find(follower_id)

      invitation_id = EntourageInvitation.where(invitable: @record, inviter: user, invitee_id: follower_id).pluck(:id).first

      notify(
        referent: @record,
        instance: @record,
        users: [follower],
        params: {
          object: @record.title,
          content: "#{partner.name} vous invite à rejoindre #{title(@record)}",
          extra: {
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

  def entourage_on_update
    return outing_on_update if @record.outing?
  end

  def outing_on_update
    return outing_on_update_status if @changes.keys.include?("status")
    return unless @changes.any? # it happens when neighborhoods_entourage is updated

    users = @record.accepted_members - [@record.user]

    return if users.none?

    notify(
      referent: @record,
      instance: @record,
      users: users,
      params: {
        object: @record.title,
        content: update_outing_message(@record, @changes)
      }
    )
  end

  def outing_on_update_status
    return outing_on_cancel if @record.cancelled?
    return outing_on_cancel if @record.closed? && @record.future_outing?

    # future notifications on other status?
  end

  def outing_on_cancel
    users = @record.accepted_members - [@record.user]

    return if users.none?

    notify(
      referent: @record,
      instance: @record,
      users: users,
      params: {
        object: @record.title,
        content: CANCEL_OUTING % to_date(@record.starts_at)
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

  def public_chat_message_on_create
    users = @record.messageable.accepted_members - [@record.user]

    return if users.none?

    notify(
      referent: @record.messageable,
      instance: @record.messageable,
      users: users,
      params: {
        object: "#{username(@record.user)} - #{title(@record.messageable)}",
        content: @record.content,
        extra: {
          group_type: group_type(@record.messageable),
          joinable_id: @record.messageable_id,
          joinable_type: @record.messageable_type,
          type: "NEW_CHAT_MESSAGE"
        }
      }
    )
  end

  def private_chat_message_on_create
    users = @record.messageable.accepted_members - [@record.user]

    return if users.none?

    notify(
      referent: @record.messageable,
      instance: @record.messageable,
      users: users,
      params: {
        object: username(@record.user),
        content: @record.content,
        extra: {
          group_type: group_type(@record.messageable),
          joinable_id: @record.messageable_id,
          joinable_type: @record.messageable_type,
          type: "NEW_CHAT_MESSAGE"
        }
      }
    )
  end

  def post_on_create
    users = @record.messageable.accepted_members - [@record.user]

    return if users.none?

    notify(
      referent: @record.messageable,
      instance: @record.messageable,
      users: users,
      params: {
        object: title(@record.messageable),
        content: CREATE_POST % [username(@record.user), @record.content],
        extra: {
          group_type: group_type(@record.messageable),
          joinable_id: @record.messageable_id,
          joinable_type: @record.messageable_type,
          type: "NEW_CHAT_MESSAGE"
        }
      }
    )
  end

  def comment_on_create
    return unless @record.has_parent?

    user_ids = @record.siblings.pluck(:user_id).uniq + [@record.parent.user_id] - [@record.user_id]

    return unless user_ids.any?

    # should redirect to post
    notify(
      referent: @record.messageable,
      instance: @record.parent,
      users: User.where(id: user_ids),
      params: {
        object: title(@record.messageable),
        content: CREATE_COMMENT % [username(@record.user), @record.content]
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

    notify(
      referent: @record.joinable,
      instance: @record.user,
      users: [@record.joinable.user],
      params: {
        object: "Nouveau membre",
        content: content,
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

  def join_request_on_update
    return unless @changes.keys.include?("status")
    return join_request_on_create unless @changes["status"] && @changes["status"].first&.to_sym == :pending

    notify(
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
  def notify referent:, instance:, users:, params: {}
    notify_push(referent: referent, instance: instance, users: users, params: params)
    notify_inapp(referent: referent, instance: instance, users: users, params: params)
  end

  def notify_push referent:, instance:, users:, params: {}
    instance = PushNotificationLinker.get(instance)
    referent = PushNotificationLinker.get(referent)

    PushNotificationService.new.send_notification(
      params[:sender],
      params[:object],
      params[:content],
      users,
      referent[:instance].singularize,
      referent[:id],
      instance.merge(params[:extra] || {})
    )
  end

  def notify_inapp referent:, instance:, users:, params: {}
    instance = PushNotificationLinker.get(instance)
    referent = PushNotificationLinker.get(referent)

    return unless instance.any?

    users.map do |user|
      InappNotificationServices::Builder.new(user).instanciate(
        context: @method,
        instance: instance[:instance].singularize,
        instance_id: instance[:id],
        post_id: instance[:post_id],
        referent: referent[:instance].singularize,
        referent_id: referent[:id],
        content: params[:content]
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
