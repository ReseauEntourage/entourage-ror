class BadgeSubscriber
  def self.register!
    EventBus.subscribe("join_request.created", method(:on_join_request))
    EventBus.subscribe("join_request.updated", method(:on_join_request))

    EventBus.subscribe("chat_message.created", method(:on_chat_message))

    EventBus.subscribe("users_resource.created", method(:on_users_resource))
    EventBus.subscribe("users_resource.updated", method(:on_users_resource))

    EventBus.subscribe("user_reaction.created", method(:on_user_reaction))

    EventBus.subscribe("entourage.created", method(:on_entourage))
  end

  def self.on_join_request(payload)
    join_request = payload[:record]

    return unless join_request.accepted?

    BadgeService.check_bienvenue(join_request.user) if join_request.outing?
    BadgeService.check_fidele_papotages(join_request.user) if join_request.papotage?
  end

  def self.on_chat_message(payload)
    chat_message = payload[:record]

    BadgeService.check_bienvenue(chat_message.user) unless chat_message.conversation?
    BadgeService.check_premier_contact(chat_message) if chat_message.conversation?
    BadgeService.check_fidele_papotages(chat_message.user) if chat_message.papotage?
  end

  def self.on_users_resource(payload)
    users_resource = payload[:record]

    return unless users_resource.watched?

    BadgeService.check_bienvenue(users_resource.user)
  end

  def self.on_user_reaction(payload)
    user_reaction = payload[:record]

    BadgeService.check_bienvenue(user_reaction.user)
    BadgeService.check_voix_presente(user_reaction.user) if user_reaction.neighborhood?
  end

  def self.on_entourage(payload)
    entourage = payload[:record]

    BadgeService.check_moteur_rencontres(entourage.user) if entourage.outing?
  end
end
