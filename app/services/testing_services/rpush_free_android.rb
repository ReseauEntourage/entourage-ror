require 'net/http'
require 'uri'
require 'json'

module TestingServices
  class RpushFreeAndroid
    FCM_URL = "https://fcm.googleapis.com/v1/projects/entourage-90011/messages:send".freeze
    SCOPE = "https://www.googleapis.com/auth/firebase.messaging".freeze

    attr_accessor :app, :device_token, :authorizer, :access_token, :service_account

    def initialize app, device_token
      @device_token = device_token
      @app = app

      @service_account = JSON.parse(app.json_key) rescue nil
      raise 'service_account failed' unless service_account

      @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(@service_account.to_json),
        scope: SCOPE
      )
      @authorizer.fetch_access_token!
      @access_token = authorizer.access_token
    end

    def push
      raise 'app should be apnsp8' unless app.is_a?(Rpush::Fcm::App)

      uri = URI("https://fcm.googleapis.com/v1/projects/#{service_account["project_id"]}/messages:send")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{access_token}"
      }

      payload = {
        message: {
          token: device_token,
          notification: {
            title: "rpush_free_android",
            body: "body"
          }
        }
      }

      request = Net::HTTP::Post.new(uri.request_uri, headers)
      request.body = payload.to_json

      response = http.request(request)
      body = JSON.parse(response.body) rescue response.body

      {
        status: response.code.to_i,
        body: body
      }
    end
  end
end
