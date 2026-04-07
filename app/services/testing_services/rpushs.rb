module TestingServices
  class Rpushs
    attr_accessor :app, :device_token

    def initialize app, device_token
      @device_token = device_token
      @app = app
    end

    def ios_push
      notification = Rpush::Apnsp8::Notification.new
      notification.app = app
      notification.device_token = device_token.to_s
      notification.alert = {
        title: "rpush_ios",
        body: "content"
      }
      notification.data = {
        sender: "rpush_ios",
        object: "object",
        content: {
          message: "content",
          extra: Hash.new
        }
      }
      notification.save!
    end

    def android_push
      notification = Rpush::Fcm::Notification.new
      notification.app = app
      notification.device_token = device_token
      notification.notification = {
        title: "rpush_android",
        body: "content"
      }.transform_values(&:to_s)

      notification.data = {
        content: {
          message: "rpush_android",
          extra: Hash.new
        }.to_json
      }

      notification.save!
    end
  end
end
