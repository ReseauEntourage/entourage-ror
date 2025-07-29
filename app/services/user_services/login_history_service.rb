module UserServices
  class LoginHistoryService
    def initialize(user:)
      @user = user
    end

    def record_login!
      create_login_history! unless already_recorded?
    end

    private
    attr_reader :user

    def already_recorded?
      $redis.get(redis_key).present?
    end

    def create_login_history!
      user.login_histories.create(connected_at: DateTime.now)
      #don't check login history for 1h
      $redis.setex(redis_key, 60*60, '1')
    end

    def redis_key
      "log_history:user:#{user.id}"
    end
  end
end
