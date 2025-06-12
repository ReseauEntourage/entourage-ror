module SmalltalkServices
  class Matcher
    def self.match_pending
      UserSmalltalk.not_matched.pluck(:id).each do |user_smalltalk_id|
        UserSmalltalk.find(user_smalltalk_id).find_and_save_match!
      end
    end
  end
end
