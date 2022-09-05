class PushNotificationTriggerObserver < ActiveRecord::Observer
  observe :entourage, :chat_message, :join_request

  CREATE_OUTING = "Un nouvel événement vient d'être ajouté au %s : %s prévu le %s"
  CANCEL_OUTING = "Cet événement prévu le %s vient d'être annulé"
  CREATE_POST = "%s vient de partager : %s"
  CREATE_COMMENT = "%s vient de commenter votre publication : %s"
  CREATE_JOIN_REQUEST = "%s vient de rejoindre votre %s : %s"

  def after_create(record)
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

  def entourage_on_create entourage
    return outing_on_create(entourage) if entourage.outing?
  end

  def outing_on_create outing
    outing.neighborhoods.each do |neighborhood|
      next unless users = (neighborhood.members.uniq - [outing.user])

      notify(instance: outing, users: users, params: {
        sender: username(outing.user),
        object: neighborhood.title,
        content: CREATE_OUTING % [entity_name(neighborhood), outing.title, to_date(outing.starts_at)]
      })
    end
  end

  def entourage_on_update entourage
    return outing_on_update(entourage) if entourage.outing?
  end

  def outing_on_update outing
    return outing_on_cancel(outing) if outing.saved_change_to_status? && outing.cancelled?

    users = outing.accepted_members - [outing.user]

    return if users.none?

    notify(instance: outing, users: users, params: {
      sender: username(outing.user),
      object: "un événement a été modifié",
      content: outing.title
    })
  end

  def outing_on_cancel outing
    users = outing.accepted_members - [outing.user]

    return if users.none?

    notify(instance: outing, users: users, params: {
      sender: username(outing.user),
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
      sender: username(public_chat_message.user),
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
      sender: username(private_chat_message.user),
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
      sender: username(post.user),
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
      sender: username(comment.user),
      object: title(comment.messageable),
      content: CREATE_COMMENT % [username(comment.user), comment.content]
    })
  end

  def join_request_on_create join_request
    return unless join_request.accepted?
    return if join_request.joinable.user == join_request.user

    notify(instance: join_request.user, users: [join_request.joinable.user], params: {
      sender: username(join_request.user),
      object: title(join_request.joinable) || "Nouveau membre",
      content: CREATE_JOIN_REQUEST % [username(join_request.user), entity_name(join_request.joinable), title(join_request.joinable)],
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
    return join_request_on_create(join_request) unless join_request.status_before_last_save&.to_sym == :pending

    notify(instance: join_request.joinable, users: [join_request.user], params: {
      sender: username(join_request.user),
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
  def notify instance:, users:, params: {}
    PushNotificationService.new.send_notification(
      params[:sender],
      params[:object],
      params[:content],
      users,
      PushNotificationLinker.get(instance).merge(params[:extra] || {})
    )
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
end
