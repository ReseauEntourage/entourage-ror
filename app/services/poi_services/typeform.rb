module PoiServices
  class Typeform
    ATTRIBUTE_CONVERSION = {
      'nom' => :name,
      'adresse ' => :adress,
      'description' => :description,
      'site internet' => :website,
      'telephone' => :phone,
      'email de la structure' => :email,
    }

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

      def convert_params params
        return unless definition = params['definition']
        return unless fields = definition['fields']
        return unless answers = params['answers']

        mapping = fields.map do |field|
          [field['id'], key_from_title(field['title'])]
        end.to_h.compact

        answers.map do |answer|
          next [nil, nil] unless field = mapping[answer['field']['id']]

          [field, answer['text']]
        end.to_h.compact
      end

      def key_from_title title
        return unless title

        ATTRIBUTE_CONVERSION.each do |key, value|
          return value if I18n.transliterate(title.downcase).include?(key)
        end

        nil
      end
    end
  end
end
