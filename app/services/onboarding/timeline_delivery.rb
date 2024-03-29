module Onboarding
  module TimelineDelivery
    MIN_DELAY = 1.hour
    MAX_DELAY = 2.days
    ACTIVE_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    ACTIVE_HOURS = '09:00'..'18:30'

    class << self
      def deliver_welcome
        now = Time.zone.now

        return unless now.strftime('%A').in?(ACTIVE_DAYS)
        return unless now.strftime('%H:%M').in?(ACTIVE_HOURS)

        User.where(id: user_ids_to_be_welcomed).find_each do |user|
          Event.track('onboarding.push_notifications.welcome.sent', user_id: user.id)
          Onboarding::Timeliner.new(user.id, :h1_after_registration).run
        end
      end

      def user_ids_to_be_welcomed
        User.where(deleted: false)
          .without_event('onboarding.push_notifications.welcome.sent')
          .where("first_sign_in_at <= ?", MIN_DELAY.ago)
          .where("first_sign_in_at >= ?", MAX_DELAY.ago)
          .pluck(:id)
      end
    end

    class << self
      def deliver_on n
        now = Time.zone.now

        return unless now.strftime('%A').in?(ACTIVE_DAYS)
        return unless now.strftime('%H:%M').in?(ACTIVE_HOURS)

        User.where(id: user_ids_after_days(n)).find_each do |user|
          Onboarding::Timeliner.new(user.id, "j#{n}_after_registration").run
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
