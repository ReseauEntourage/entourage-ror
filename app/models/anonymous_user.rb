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

  def apple?
    address&.country == 'US'
  end

  def token
    @token ||= AnonymousUserService.token_from_uuid(uuid, community: community)
  end

  attr_accessor :address

  def addresses
    [address].compact
  end

  def departement_slugs
    departements = addresses.map do |address|
      if country != 'FR' || postal_code.nil?
        departement = '*' # hors_zone
      else
        departement = postal_code.first(2)
      end
    end
    departements = ['_'] if departements.none? # sans_zone
    departements.uniq.map { |d| ModerationArea.departement_slug(d) }
  end

  def address_2; nil; end

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
  def admin?; false; end
  def email; nil; end
  def phone; nil; end
  def has_password?; false; end
  def deleted; false; end
  def partner_id; nil; end
  def partner; nil; end
  def invitations; EntourageInvitation.none; end
  def active_invitations; EntourageInvitation.none; end
  def goal; nil; end
  def interest_list; []; end
  def interests; []; end
  def birthday; nil; end
  def errors; ActiveModel::Errors.new(nil); end
  def entourage_participations; JoinRequest.none; end
  def engaged?; false; end
  def ambassador?; false; end
  def ask_for_help_creation_count; 0; end
  def contribution_creation_count; 0; end
  def travel_distance; 10; end
end
