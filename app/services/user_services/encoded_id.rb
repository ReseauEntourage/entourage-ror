module UserServices
  module EncodedId
    KEY = '6db24fb6'

    def self.encode id
      hex_id = Integer(id).to_s(16)
      [hex_id, signature(hex_id)].join
    end

    def self.decode encoded_id
      encoded_id = encoded_id.to_s
      hex_id = encoded_id[0...-4]
      sig = encoded_id[-4..-1]
      return if sig != signature(hex_id)
      hex_id.to_i(16)
    end

    private

    def self.signature hex_id
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), KEY, hex_id).first(4)
    end
  end
end
