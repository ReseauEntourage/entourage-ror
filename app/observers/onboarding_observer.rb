class OnboardingObserver < ActiveRecord::Observer
  observe :join_request, :users_resource, :chat_message

  def after_create record
    action(:create, record)
  end

  def after_update record
    action(:update, record)
  end

  private

  def action verb, record
    return action_join_request(record) if record.is_a?(JoinRequest)
    return action_users_resource(record) if record.is_a?(UsersResource)
    return action_chat_message(record) if record.is_a?(ChatMessage)
  rescue
    # we want this hook to never fail the main process
  end

  def action_join_request join_request
    return unless join_request.accepted?
    return unless join_request.outing?

    # avoid join_request.joinable: we need to cast an Outing, not an Entourage
    outing = Outing.find(join_request.joinable_id)

    return unless outing.online?

    if outing.webinar? || outing.first_steps?
      return join_request.user.webinar_or_first_steps_joined!
    end

    if outing.papotage?
      return join_request.user.papotages_joined!
    end
  end

  def action_users_resource users_resource
    return unless users_resource.watched?
    return unless users_resource.resource.is_welcome_video?

    users_resource.user.welcome_watched!
  end

  def action_chat_message chat_message
    return unless chat_message.neighborhood?
    return unless chat_message.text?
    return unless chat_message.user.default_neighborhood == chat_message.messageable

    chat_message.user.neighborhood_post!
  end
end
