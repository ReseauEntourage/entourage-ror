class PushNotificationTriggerObserver < ActiveRecord::Observer
  observe :entourage, :chat_message, :join_request, :neighborhoods_entourage

  CREATE_OUTING = "Un nouvel événement vient d'être ajouté au %s : %s prévu le %s"
  CANCEL_OUTING = "Cet événement prévu le %s vient d'être annulé"
  UPDATE_OUTING = "L'événement prévu le %s a été modifié. Il se déroulera le %s, au %s"
  UPDATE_OUTING_SHORT = "L'événement prévu le %s a été modifié"
  CREATE_POST = "%s vient de partager : \"%s\""
  CREATE_COMMENT = "%s vient de commenter votre publication \"%s\""
  CREATE_JOIN_REQUEST = "%s vient de rejoindre votre %s \"%s\""
  CREATE_JOIN_REQUEST_OUTING = "%s vient de rejoindre votre événement \"%s\" du %s"

  def after_create(record)
    return unless record.persisted?

    action(:create, record)
  end

  def after_update(record)
    action(:update, record)
  end

  # @param verb :create, :update
  # @param record instance of entourage, chat_message, join_request
  def action(verb, record)
    method = "#{record.class.name.underscore}_on_#{verb.to_s}".to_sym
    return unless self.class.method_defined?(method)

    send(method, record)
  end

  protected

  def neighborhoods_entourage_on_create neighborhoods_entourage
    neighborhood = neighborhoods_entourage.neighborhood
    entourage = neighborhoods_entourage.entourage

    return unless entourage.outing?
    return unless users = (neighborhood.members.uniq - [entourage.user])

    notify(instance: entourage, users: users, params: {
      object: neighborhood.title,
      content: CREATE_OUTING % [entity_name(neighborhood), entourage.title, to_date(entourage.starts_at)]
    })
  end

  def entourage_on_create entourage
    return unless entourage.outing? || entourage.action?
    return unless user = entourage.user
    return unless partner = user.partner

    follower_ids = Following.where(partner: partner, active: true).pluck(:user_id)

    return unless follower_ids.any?

    follower_ids.each do |follower_id|
      next unless follower = User.find(follower_id)

      invitation_id = EntourageInvitation.where(invitable: entourage, inviter: user, invitee_id: follower_id).pluck(:id).first

      notify(instance: entourage, users: [follower], params: {
        object: entourage.title,
        content: "#{partner.name} vous invite à rejoindre #{title(entourage)}",
        extra: {
          type: "ENTOURAGE_INVITATION",
          entourage_id: entourage.id,
          group_type: entourage.group_type,
          inviter_id: user.id,
          invitee_id: follower_id,
          invitation_id: invitation_id
        }
      })
    end
  end

  def entourage_on_update entourage
    return outing_on_update(entourage) if entourage.outing?
  end

  def outing_on_update outing
    return outing_on_update_status(outing) if outing.saved_change_to_status?
    return unless outing.saved_changes.any? # it happens when neighborhoods_entourage is updated

    users = outing.accepted_members - [outing.user]

    return if users.none?

    notify(instance: outing, users: users, params: {
      object: outing.title,
      content: update_outing_message(outing)
    })
  end

  def outing_on_update_status outing
    return outing_on_cancel(outing) if outing.cancelled?

    # future notifications on other status?
  end

  def outing_on_cancel outing
    users = outing.accepted_members - [outing.user]

    return if users.none?

    notify(instance: outing, users: users, params: {
      object: outing.title,
      content: CANCEL_OUTING % to_date(outing.starts_at)
    })
  end

  def chat_message_on_create chat_message
    return unless ['text', 'broadcast'].include? chat_message.message_type

    return comment_on_create(chat_message) if chat_message.has_parent?
    return post_on_create(chat_message) if chat_message.messageable.is_a?(Neighborhood)
    return post_on_create(chat_message) if chat_message.messageable.respond_to?(:outing?) && chat_message.messageable.outing?
    return public_chat_message_on_create(chat_message) if chat_message.messageable.respond_to?(:action?) && chat_message.messageable.action?

    private_chat_message_on_create(chat_message)
  end

  def public_chat_message_on_create public_chat_message
    users = public_chat_message.messageable.accepted_members - [public_chat_message.user]

    return if users.none?

    notify(instance: public_chat_message.messageable, users: users, params: {
      object: "#{username(public_chat_message.user)} - #{title(public_chat_message.messageable)}",
      content: public_chat_message.content,
      extra: {
        group_type: group_type(public_chat_message.messageable),
        joinable_id: public_chat_message.messageable_id,
        joinable_type: public_chat_message.messageable_type,
        type: "NEW_CHAT_MESSAGE"
      }
    })
  end

  def private_chat_message_on_create private_chat_message
    users = private_chat_message.messageable.accepted_members - [private_chat_message.user]

    return if users.none?

    notify(instance: private_chat_message.messageable, users: users, params: {
      object: username(private_chat_message.user),
      content: private_chat_message.content,
      extra: {
        group_type: group_type(private_chat_message.messageable),
        joinable_id: private_chat_message.messageable_id,
        joinable_type: private_chat_message.messageable_type,
        type: "NEW_CHAT_MESSAGE"
      }
    })
  end

  def post_on_create post
    users = post.messageable.accepted_members - [post.user]

    return if users.none?

    notify(instance: post.messageable, users: users, params: {
      object: title(post.messageable),
      content: CREATE_POST % [username(post.user), post.content],
      extra: {
        group_type: group_type(post.messageable),
        joinable_id: post.messageable_id,
        joinable_type: post.messageable_type,
        type: "NEW_CHAT_MESSAGE"
      }
    })
  end

  def comment_on_create comment
    return if comment.parent.user == comment.user

    notify(instance: comment.messageable, users: [comment.parent.user], params: {
      object: title(comment.messageable),
      content: CREATE_COMMENT % [username(comment.user), comment.content]
    })
  end

  def join_request_on_create join_request
    return unless join_request.accepted?
    return if join_request.joinable.is_a?(Entourage) && join_request.joinable.conversation?
    return if join_request.joinable.user == join_request.user

    content = if join_request.joinable.is_a?(Entourage) && join_request.joinable.outing?
      CREATE_JOIN_REQUEST_OUTING % [username(join_request.user), title(join_request.joinable), to_date(join_request.joinable.starts_at)]
    else
      CREATE_JOIN_REQUEST % [username(join_request.user), entity_name(join_request.joinable), title(join_request.joinable)]
    end

    notify(instance: join_request.user, users: [join_request.joinable.user], params: {
      object: "Nouveau membre",
      content: content,
      extra: {
        joinable_id: join_request.joinable_id,
        joinable_type: join_request.joinable_type,
        group_type: group_type(join_request.joinable),
        type: "JOIN_REQUEST_ACCEPTED",
        user_id: join_request.user_id
      }
    })
  end

  def join_request_on_update join_request
    return unless join_request.saved_change_to_status?
    return join_request_on_create(join_request) unless join_request.status_before_last_save&.to_sym == :pending

    notify(instance: join_request.joinable, users: [join_request.user], params: {
      object: title(join_request.joinable) || "Demande acceptée",
      content: "Vous venez de rejoindre un(e) #{entity_name(join_request.joinable)} de #{username(join_request.joinable.user)}",
      extra: {
        joinable_id: join_request.joinable_id,
        joinable_type: join_request.joinable_type,
        group_type: group_type(join_request.joinable),
        type: "JOIN_REQUEST_ACCEPTED",
        user_id: join_request.user_id
      }
    })
  end

  # use params[:extra] to be compliant with v7
  # @caution notifications should be instanciated in jobs
  def notify instance:, users:, params: {}
    object = PushNotificationLinker.get(instance)

    # @jobs!

    # push notifications
    PushNotificationService.new.send_notification(
      params[:sender],
      params[:object],
      params[:content],
      users,
      object.merge(params[:extra] || {})
    )

    return unless object.any?

    # inapp notifications
    users.map do |user|
      InappNotificationServices::Builder.new(user).instanciate(instance: object[:instance].singularize, instance_id: object[:id])
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

  def update_outing_message outing
    if outing.metadata_before_last_save[:starts_at] == outing.starts_at && outing.metadata_before_last_save[:display_address] == outing.metadata[:display_address]
      return UPDATE_OUTING_SHORT % to_date(outing.starts_at)
    end

    UPDATE_OUTING % [
      to_date(outing.metadata_before_last_save[:starts_at]),
      to_date(outing.starts_at),
      outing.metadata[:display_address]
    ]
  end
end
