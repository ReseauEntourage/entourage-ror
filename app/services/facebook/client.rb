module Facebook
  class Client
    attr_reader :token

    def initialize(token:)
      @token = token
    end

    def me
      get("https://graph.facebook.com/me")
    end


    def get(url)
      uri = URI.parse(url)

      uri.query = URI.encode_www_form({'access_token' => token, 'fields' => 'id,email,first_name,last_name,gender,location,birthday'})
      req = Net::HTTP::Get.new uri.request_uri

      res = Net::HTTP.new(uri.host, uri.port)
      res.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res.use_ssl = true
      res.read_timeout = res.open_timeout = 1 #very important: fail fast if facebook is not answering within 1sec

      response = nil
      res.start do |http|
        response = http.request(req)
        raise Facebook::InvalidTokenError if response.code=="400"
        response = JSON.parse(response.body)
        raise Facebook::FacebookResponseWithError.new(response.dig("error", "message")) if response["error"].present?
        response
      end
    end
  end

  class InvalidTokenError < StandardError; end
  class FacebookResponseWithError < StandardError; end
end
