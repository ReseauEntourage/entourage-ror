module SmalltalkServices
  class Matcher
    class << self
      def match_pending
        UserSmalltalk.not_matched.pluck(:id).each do |user_smalltalk_id|
          user_smalltalk = UserSmalltalk.find(user_smalltalk_id)

          next if user_smalltalk.find_and_save_match!

          almost_match!(user_smalltalk)
        end
      end

      def almost_match! user_smalltalk
        # temporary deactivation
        return

        return unless user_smalltalk.created_at < 4.days.ago
        return unless user_smalltalk.last_almost_match_computation_at.blank? || user_smalltalk.last_almost_match_computation_at < 4.days.ago

        almost_matches = user_smalltalk.find_almost_matches

        return unless almost_matches.any?

        PushNotificationTrigger.new(user_smalltalk, :almost_match, Hash.new).run
      end
    end

    def self.close_unmatched
      UserSmalltalk.not_matched.where('created_at < ?', 15.days.ago).find_each do |user_smalltalk|
        user_smalltalk.update(deleted_at: Time.zone.now)

        # using an observer is not possible to send this notification
        # this notification is only sent from this job and not on all deletions
        PushNotificationTrigger.new(user_smalltalk, :expire, Hash.new).run
      end
    end
  end
end
