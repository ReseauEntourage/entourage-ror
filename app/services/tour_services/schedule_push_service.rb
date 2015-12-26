module TourServices
  class SchedulePushService
    def initialize(organization:, date:)
      @organization = organization
      @date = date
      raise TourServices::InvalidScheduledPushDateError.new("Cannot schedule a push with past date : #{date}") if date < Date.today
    end

    def schedule(object:, message:)
      $redis.mapped_hmset(key, {object: object, message: message})
      $redis.expire(key, (date.to_time.to_i-DateTime.now.to_i))
    end

    def scheduled_message
      $redis.hgetall(key)
    end

    private
    attr_reader :organization, :date

    def key
      "scheduled_message:organization:#{organization.id}:date:#{date}"
    end
  end

  class InvalidScheduledPushDateError < StandardError; end
end