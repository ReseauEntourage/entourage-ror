class Neighborhood < ApplicationRecord
  include Interestable

  belongs_to :user

  after_create do |neighborhood|
    JoinRequest.create!(role: :creator, joinable: neighborhood, user: neighborhood.user, status: :accepted)
  rescue
    raise ActiveRecord::Rollback
  end

  alias_attribute :author, :user

  has_many :join_requests, as: :joinable, dependent: :destroy
  has_many :members, through: :join_requests, source: :user
  has_many :neighborhoods_entourages

  has_many :outings, -> { where(group_type: :outing) }, through: :neighborhoods_entourages, source: :entourage

  reverse_geocoded_by :latitude, :longitude
  has_many :chat_messages, as: :messageable, dependent: :destroy

  validates_presence_of [:name, :latitude, :longitude]

  alias_attribute :title, :name

  # valides :image_url # should be 390x258 (2/3)
  attr_accessor :neighborhood_image_id

  scope :inside_perimeter, -> (latitude, longitude, travel_distance) {
    if latitude && longitude
      where("#{PostgisHelper.distance_from(latitude, longitude)} < ?", travel_distance)
    end
  }
  scope :order_by_distance_from, -> (latitude, longitude) {
    if latitude && longitude
      order(PostgisHelper.distance_from(latitude, longitude))
    end
  }
  scope :order_by_interests_matching, -> (interest_list) {
    # @todo
  }
  scope :order_by_activity, -> {
    # @todo
  }
  scope :like, -> (search) {
    return unless search.present?

    where('(unaccent(name) ilike unaccent(:name) or unaccent(description) ilike unaccent(:description))', {
      name: "%#{search.strip}%",
      description: "%#{search.strip}%"
    })
  }
  scope :joined_by, -> (user) {
    joins(:join_requests).where(join_requests: {
      user: user, status: JoinRequest::ACCEPTED_STATUS
    })
  }
  scope :not_joined_by, -> (user) {
    where.not(id: Neighborhood.joined_by(user))
  }

  def google_place_id= google_place_id
    google_place_details = UserServices::AddressService.fetch_google_place_details(google_place_id)

    self.place_name = google_place_details[:place_name]
    self.postal_code = google_place_details[:postal_code]
    self.latitude = google_place_details[:latitude]
    self.longitude = google_place_details[:longitude]
  end

  # behaviors

  # EC-94: list neighborhoods [OK]
  # EC-95: join neighborhood [OK]
  # EC-117: leave neighborhood [OK]
  # EC-95: show neighborhood [OK]
  # EC-99: find neighborhood
  # EC-100: create neighborhood [OK]
  # EC-118: add photo to neighborhood [OK]
  # EC-101: update neighborhood [OK]
  # EC-104: add localization to neighborhood
  # main: post message in neighborhood conversation [OK]
  # main: receive notification when message has been post [OK]
  # main: create outing in neighborhood [OK]
  # main: signal neighborhood
  # main: signal a user in neighborhood (ethics)

  # EC-82 [groupe] modérer la création d'un groupe
  # EC-83 [groupe] être notifié sur la création d'un groupe
  # EC-84 [groupe] détecter groupes similaires
  # EC-85 [groupe] détecter groupes abusifs : détection
  # EC-86 [groupe] détecter groupes abusifs : design interface
  # EC-88 [groupe] détecter groupes abusifs : notification
  # EC-89 [modé] détecter mots abusifs sur contenu publié : détection
  # EC-90 [modé] détecter mots abusifs sur contenu publié : design interface
  # EC-91 [modé] détecter mots abusifs sur contenu publié : notification
  # EC-92 [groupe] éditer les infos d'un groupe

  def members_count
    members.count
  end

  def past_outings
    outings.where("metadata->>'ends_at' < ?", Time.zone.now)
  end

  def past_outings_count
    past_outings.count
  end

  def future_outings
    outings.where("metadata->>'starts_at' > ?", Time.zone.now)
  end

  def future_outings_count
    future_outings.count
  end

  def ongoing_outings
    outings.where("metadata->>'starts_at' >= ?", Time.zone.now).where("metadata->>'ends_at' <= ?", Time.zone.now)
  end

  def has_ongoing_outing?
    ongoing_outings.any?
  end

  # @code_legacy
  def group_type
    'neighborhood'
  end

  # @code_legacy
  def group_type_config
    {
      'message_types' => ['text', 'share'],
      'roles' => ['admin', 'member']
    }
  end

  def image_url
    return unless self['image_url'].present?

    NeighborhoodImage.image_url_for self['image_url']
  end

  def neighborhood_image_id= neighborhood_image_id
    if neighborhood_image = NeighborhoodImage.find_by_id(neighborhood_image_id)
      self.image_url = neighborhood_image[:image_url]
    else
      remove_neighborhood_image_id!
    end
  end

  def remove_neighborhood_image_id!
    self.image_url = nil
  end
end
