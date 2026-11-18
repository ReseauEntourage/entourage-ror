Rails.application.config.to_prepare do
  BadgeSubscriber.register!
  NextStepRealisationSubscriber.register!
end
