class UnseenResourceWelcomeJob
  include Sidekiq::Worker

  EVENT_NAME = 'onboarding.resource.welcome_unseen'

  def perform user_id
    user = User.find_by_id(user_id)
    return unless user
    return if user.deleted? || user.blocked?
    return unless user.is_offer_help? || user.is_ask_for_help?

    welcome_video = Resource.find_by(tag: :welcome)
    return unless welcome_video
    return if user.has_watched_resource?(welcome_video.id)
    return if Event.where(name: EVENT_NAME, user_id: user.id).exists?

    object = PushNotificationTrigger::I18nStruct.new(text: '1 minute pour tout comprendre 🎥')
    content = PushNotificationTrigger::I18nStruct.new(text: "Notre vidéo de présentation vous attend. C'est rapide, et ça vaut le coup.")

    PushNotificationService.new.send_notification(
      nil,
      object,
      content,
      [user],
      'resource',
      welcome_video.id,
      { instance: 'resource', instance_id: welcome_video.id, tracking: :unseen_video_push_notification }
    )

    Event.track(EVENT_NAME, user_id: user.id)
  end
end
