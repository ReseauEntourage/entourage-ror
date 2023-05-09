module Onboarding
  module PushNotificationService
    MIN_DELAY = 1.hour
    ACTIVE_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    ACTIVE_HOURS = '09:00'..'18:30'

    class << self
      def deliver_welcome
        now = Time.zone.now

        return unless now.strftime('%A').in?(ACTIVE_DAYS)
        return unless now.strftime('%H:%M').in?(ACTIVE_HOURS)

        User.where(id: user_ids_to_be_welcomed).find_each do |user|
          Event.track('onboarding.push_notifications.welcome.sent', user_id: user.id)
          PushNotificationTimeliner.new(user.id, :h1_after_registration)
        end
      end

      def user_ids_to_be_welcomed
        User.where(deleted: false)
          .without_event('onboarding.push_notifications.welcome.sent')
          .where("first_sign_in_at <= ?", MIN_DELAY.ago)
          .pluck(:id)
      end
    end

    class << self
      def deliver_on n
        now = Time.zone.now

        return unless now.strftime('%A').in?(ACTIVE_DAYS)
        return unless now.strftime('%H:%M').in?(ACTIVE_HOURS)

        User.where(id: user_ids_after_days(n)).find_each do |user|
          PushNotificationTimeliner.new(user.id, "j#{n}_after_registration").run
        end
      end

      def user_ids_after_days n
        User.where(deleted: false)
          .where(first_sign_in_at: n.days.ago.all_day)
          .pluck(:id)
      end
    end
  end
end
