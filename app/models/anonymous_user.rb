class AnonymousUser
  include ActiveModel::Serialization

  ATTRIBUTES = [
    :token,
    :community,
  ].freeze

  attr_reader *ATTRIBUTES

  def initialize(attributes={})
    attributes.symbolize_keys!
    @token = attributes[:token].to_str
    @community = Community.new(attributes[:community])
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
end
