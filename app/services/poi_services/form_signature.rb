module PoiServices
  class FormSignature
    attr_reader :request

    def initialize request
      @request = request
    end

    def verify
      return false unless secret = ENV['POI_FORM_SECRET_TOKEN']
      return false unless signature = request.env['HTTP_TYPEFORM_SIGNATURE']

      request.body.rewind

      Rack::Utils.secure_compare(
        "sha256=#{self.class.base64_hash(secret, request.body.read)}",
        signature
      )
    end

    class << self
      def base64_hash secret, body_query
        hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secret, body_query)

        Base64.strict_encode64(hash)
      end
    end
  end
end
