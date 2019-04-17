module AnonymousUserService
  def self.create_user community
    AnonymousUser.new(
      uuid: SecureRandom.uuid,
      community: community
    )
  end

  def self.token_from_uuid uuid, community:
    version = 1
    signature = SignatureService.sign(uuid, salt: salt(community))
    [version, :anonymous, uuid, signature].join('_')
  end

  def self.uuid_from_token token, community:
    return false unless token.respond_to? :to_str
    token = token.to_str

    return false unless token.starts_with?('1_anonymous_')

    _version, _prefix, uuid, signature = token.split('_', 4)

    return false if uuid.length != 36 || signature.length != 40

    return false unless SignatureService.validate(uuid, signature, salt: salt(community))

    uuid
  end

  def self.find_user_by_token token, community:
    uuid = uuid_from_token(token, community: community)

    return nil if uuid == false
    AnonymousUser.new(
      uuid: uuid,
      community: community
    )
  end

  def self.potential_token? token
    token.to_s.starts_with?('1_anonymous_')
  end

  def self.token? string, community:
    uuid_from_token(string, community: community) != false
  end

  def self.salt community
    "anonymous_user_token.#{community.slug}"
  end
end
