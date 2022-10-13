module InappNotificationServices
  class Builder
    OBSOLETE_PERIOD = 7.days

    attr_accessor :user

    def initialize user
      @user = user
    end

    def skip_obsolete_notifications
      user.inapp_notifications.active.each do |inapp_notification|
        inapp_notification.update_attribute(:skipped_at, Time.now) if inapp_notification.created_at < OBSOLETE_PERIOD.ago
      end
    end

    def instanciate instance:, instance_id:
      return if configuration && configuration.not_accepted?(instance: instance)

      InappNotification.new(
        user: user,
        instance: instance,
        instance_id: instance_id
      )
    end

    def configuration
      @configuration ||= user.notification_configuration&.configuration
    end
  end
end
