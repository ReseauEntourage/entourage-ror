module AnonymousUserService
  def self.create_user community
    uuid = SecureRandom.uuid
    signature = SignatureService.sign(uuid, salt: salt(community))
    version = 1
    token = [:anonymous, version, uuid, signature].join('.')
    AnonymousUser.new(
      token: token,
      community: community
    )
  end

  def self.find_user_by_token token, community:
    return nil unless token?(token, community: community)
    AnonymousUser.new(
      token: token,
      community: community
    )
  end

  def self.token? string, community:
    return false unless string.respond_to? :to_str
    string = string.to_str
    return false unless string.starts_with?("anonymous.")
    _, version, uuid, signature = string.split('.', 4)
    return false if [version, uuid, signature].any?(&:nil?)
    version = Integer(version) rescue nil
    return false if version != 1
    return false if uuid.length != 36 || signature.length != 40
    SignatureService.validate(uuid, signature, salt: salt(community))
  end

  def self.salt community
    "anonymous_user_token.#{community.slug}"
  end
end
