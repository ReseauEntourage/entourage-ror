class PushNotificationTriggerObserver < ActiveRecord::Observer
  observe :entourage, :chat_message, :join_request

  def after_create(record)
    action(:create, record)
  end

  def after_update(record)
    action(:update, record)
  end

  # @param verb :create, :update
  # @param record instance of entourage, chat_message, join_request
  def action(verb, record)
    if record.instance_of? Entourage
      record = record.becomes(Outing) if record.outing?
    end

    method = "#{record.class.name.underscore}_on_#{verb.to_s}".to_sym
    return unless self.class.method_defined?(method)

    send(method, record)
  end

  protected

  def outing_on_create outing
    users = outing.neighborhoods.map(&:members).flatten.uniq - [outing.user]

    return if users.none?

    notify(instance: outing, users: users, params: {
      sender: username(outing.user),
      object: "un événement a été créé",
      content: outing.title
    })
  end

  def outing_on_update outing
    return cancel_on_outing(outing) if outing.saved_change_to_status? && outing.status == :cancelled

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
      object: "un événement a été annulé",
      content: outing.title
    })
  end

  def chat_message_on_create chat_message
    return unless ['text', 'broadcast'].include? chat_message.message_type

    return comment_on_create(chat_message) if chat_message.has_parent?

    post_on_create(chat_message)
  end

  def post_on_create post
    users = post.messageable.accepted_members - [post.user]

    return if users.none?

    notify(instance: post.messageable, users: users, params: {
      sender: username(post.user),
      object: title(post.messageable),
      content: post.content,
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
      object: "un commentaire a été posté",
      content: comment.content
    })
  end

  def join_request_on_create join_request
    return unless join_request.accepted?

    notify(instance: join_request.user, users: [join_request.joinable.user], params: {
      sender: username(join_request.user),
      object: title(join_request.joinable) || "Nouveau membre",
      content: "#{username(join_request.user)} vient de rejoindre votre #{GroupService.name(join_request.joinable)}",
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
end
