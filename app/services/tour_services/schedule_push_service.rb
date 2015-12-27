module TourServices
  class SchedulePushService
    def initialize(organization:, date:)
      @organization = organization
      @date = date
      if date < Date.today
        raise TourServices::InvalidScheduledPushDateError.new(
            "Cannot schedule a push with past date : #{date}")
      end
    end

    def schedule(object:, message:, sender:)
      $redis.mapped_hmset(key, {object: object, message: message, sender: sender})
      $redis.expire(key, (date.to_time.to_i-DateTime.now.to_i))
    end

    def scheduled_message
      @scheduled_message ||= $redis.hgetall(key)
    end

    def send_to(user)
      return if scheduled_message.blank?
      push_service.send_notification(scheduled_message[:sender],
                                     scheduled_message[:object],
                                     scheduled_message[:message],
                                     User.where(id: user.id))
    end

    def destroy
      $redis.del(key)
    end

    def self.all_scheduled_pushes(organization:)
      $redis.keys("scheduled_message:organization:#{organization.id}*").map  do |key|
        date = key.split(":").last
        message = $redis.hgetall(key)
        message.merge({"date" => date})
      end.sort_by { |msg| Date.parse(msg["date"]) }
    end

    private
    attr_reader :organization, :date

    def key
      "scheduled_message:organization:#{organization.id}:date:#{date}"
    end

    def push_service
      PushNotificationService.new
    end
  end

  class InvalidScheduledPushDateError < StandardError; end
end