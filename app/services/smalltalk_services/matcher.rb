module SmalltalkServices
  class Matcher
    def self.close_unmatched
      UserSmalltalk.not_matched.where('created_at < ?', 15.days.ago).find_each do |user_smalltalk|
        user_smalltalk.update(deleted_at: Time.zone.now)

        # using an observer is not possible to send this notification
        # this notification is only sent from this job and not on all deletions
        PushNotificationTrigger.new(user_smalltalk, :expire, Hash.new).run
      end
    end

    def self.match_pending
      UserSmalltalk.not_matched.pluck(:id).each do |user_smalltalk_id|
        UserSmalltalk.find(user_smalltalk_id).find_and_save_match!
      end
    end
  end
end
