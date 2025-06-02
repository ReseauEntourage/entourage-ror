Rails.application.config.to_prepare do
  ActiveSupport::Notifications.subscribe('members_changed.joinable') do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    MembersSubscriber.new.members_changed(event)
  end
end
