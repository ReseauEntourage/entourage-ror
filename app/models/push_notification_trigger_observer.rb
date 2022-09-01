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
      sender: outing.user.full_name,
      object: "un événement a été créé",
      content: outing.title
    })
  end

  def outing_on_update outing
    return cancel_on_outing(outing) if outing.saved_change_to_status? && outing.status == :cancelled

    users = outing.accepted_members - [outing.user]

    return if users.none?

    notify(instance: outing, users: users, params: {
      sender: outing.user.full_name,
      object: "un événement a été modifié",
      content: outing.title
    })
  end

  def outing_on_cancel outing
    users = outing.accepted_members - [outing.user]

    return if users.none?

    notify(instance: outing, users: users, params: {
      sender: outing.user.full_name,
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
      sender: post.user.full_name,
      object: "un post a été posté",
      content: post.content
    })
  end

  def comment_on_create comment
    return if comment.parent.user == comment.user

    notify(instance: comment.messageable, users: [comment.parent.user], params: {
      sender: comment.user.full_name,
      object: "un commentaire a été posté",
      content: comment.content
    })
  end

  def join_request_on_create join_request
    notify(instance: join_request.user, users: [join_request.joinable.user], params: {
      sender: join_request.user.full_name,
      object: "un membre vient de rejoindre",
      content: "n/a"
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
end
