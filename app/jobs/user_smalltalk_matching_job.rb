class UserSmalltalkMatchingJob
  include Sidekiq::Job

  def perform
    UserSmalltalk.not_matched.find_each do |user_smalltalk|
      begin
        user_smalltalk.find_and_save_match! if user_smalltalk.find_match
      rescue => e
        Rails.logger.error("⚠️ Matching failed for UserSmalltalk #{user_smalltalk.id}: #{e.message}")
      end
    end
  end
end
