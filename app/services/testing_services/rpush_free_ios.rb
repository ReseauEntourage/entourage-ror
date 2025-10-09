require 'apnotic'
require 'tempfile'

module TestingServices
  class RpushFreeIos
    attr_accessor :app, :device_token

    def initialize app, device_token
      @device_token = device_token
      @app = app
    end

    def push
      raise 'app should be apnsp8' unless app.is_a?(Rpush::Apnsp8::App)

      Tempfile.create(["apns_authkey", ".p8"]) do |file|
        file.write(app.apn_key)
        file.flush

        connection = Apnotic::Connection.new(
          auth_method: :token,
          cert_path: file.path,
          key_id: app.apn_key_id,
          team_id: app.team_id,
          topic: app.bundle_id,
          environment: app.environment
        )

        notification = Apnotic::Notification.new(device_token)
        notification.topic = app.bundle_id
        notification.alert = {
          title: "rpush_free_android",
          body: "body"
        }

        response = connection.push(notification)

        return {
          status: response.status,
          headers: response.headers,
          body: response.body
        }
      ensure
        connection.close if connection
      end
    end
  end
end
