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

    def instanciate context:, instance:, instance_id:, content:
      return unless accepted_configuration?(context, instance, instance_id)

      notification = InappNotification.find_or_initialize_by(
        user: user,
        instance: instance,
        instance_id: instance_id,
        context: context,
        completed_at: nil,
        skipped_at: nil
      )

      return unless notification.new_record?

      notification.content = content
      notification.save
    end

    def accepted_configuration? context, instance, instance_id
      return true unless configuration = user.notification_configuration

      configuration.notify?(context, instance, instance_id)
    end
  end
end
