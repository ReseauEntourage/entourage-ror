module SlackServices
  class JulesRequestVerification
    def initialize(request)
      @request = request
    end

    def verify!
      return true if Rails.env.development? || Rails.env.test?

      signing_secret = ENV['SLACK_SIGNING_SECRET']
      return false if signing_secret.blank?

      timestamp = @request.headers['X-Slack-Request-Timestamp']
      signature = @request.headers['X-Slack-Signature']

      # Prevent replay attacks
      return false if timestamp.nil? || (Time.now.to_i - timestamp.to_i).abs > 60 * 5

      sig_basestring = "v0:#{timestamp}:#{@request.raw_post}"
      digest = OpenSSL::HMAC.hexdigest('SHA256', signing_secret, sig_basestring)
      expected_signature = "v0=#{digest}"

      ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
    end
  end
end
