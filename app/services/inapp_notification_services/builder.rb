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

    # @params context ie. chat_message_on_create
    def instanciate context:, sender_id:, instance:, instance_id:, post_id:, referent:, referent_id:, content:
      return unless NotificationPermission.notify_inapp?(user, referent, referent_id)

      notification = InappNotification.find_or_initialize_by(
        user: user,
        sender_id: sender_id,
        instance: instance,
        instance_id: instance_id,
        post_id: post_id,
        context: context,
        completed_at: nil,
        skipped_at: nil
      )

      return unless notification.new_record?

      notification.content = content
      notification.save
    end
  end
end
