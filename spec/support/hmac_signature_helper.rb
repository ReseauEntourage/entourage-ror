module HmacSignatureHelper
  RSPEC_HMAC_SECRET = 'rspec_hmac_secret'.freeze

  def sign_user_creation_request(phone:, timestamp: Time.now.to_i, secret: RSPEC_HMAC_SECRET)
    signature = OpenSSL::HMAC.base64digest('SHA256', secret, "POST\n/api/v1/users\n#{timestamp}\n#{phone}")
    # Use @request (not the `request` method) since some contexts in this
    # file shadow `request` with their own `let(:request) { post ... }`.
    @request.headers['X-Request-Timestamp'] = timestamp.to_s
    @request.headers['X-Request-Signature'] = signature
  end
end
