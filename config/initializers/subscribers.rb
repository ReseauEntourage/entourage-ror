Rails.application.config.to_prepare do
  EventBus.reset!
  BadgeSubscriber.register!
end
