class AnonymousUser
  include ActiveModel::Serialization

  ATTRIBUTES = [
    :uuid,
    :token,
    :community,
  ].freeze

  attr_reader *ATTRIBUTES

  def initialize(attributes={})
    attributes.symbolize_keys!

    @uuid = attributes[:uuid].to_str
    raise "uuid must be present" if @uuid.blank?

    @community = Community.new(attributes[:community])
    raise "community must be present" if @community.blank?

    if attributes.key?(:token)
      @token = attributes[:token].to_str
    end
  end

  def attributes
    Hash[ATTRIBUTES.map { |key| [key.to_s, send(key)] }]
  end

  def user_type
    'public'
  end

  def anonymous?
    true
  end

  def token
    @token ||= AnonymousUserService.token_from_uuid(uuid, community: community)
  end

  def id; nil; end
  def first_name; nil; end
  def last_name; nil; end
  def roles; []; end
  def about; nil; end
  def avatar_key; nil; end
  def organization; nil; end
  def tours; []; end
  def encounters; []; end
  def groups; []; end
  def join_requests; JoinRequest.none; end
  def pro?; false; end
  def email; nil; end
  def has_password?; false; end
  def address; nil; end
  def deleted; false; end
end
