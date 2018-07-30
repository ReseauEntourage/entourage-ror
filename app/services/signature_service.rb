module SignatureService
  DEFAULT_SIGNATURE_LENGTH = 40

  def self.validate key, signature, length: DEFAULT_SIGNATURE_LENGTH
    signature == sign(key, length: length)
  end

  def self.sign key, length: DEFAULT_SIGNATURE_LENGTH
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha1'),
      ENV['ENTOURAGE_SECRET'],
      key.to_s
    )
    .first(length)
  end
end
