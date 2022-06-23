class Neighborhood < ApplicationRecord
  include Interestable

  # STATUSES = [:active, :deleted]

  belongs_to :user

  after_create do |neighborhood|
    JoinRequest.create!(role: :creator, joinable: neighborhood, user: neighborhood.user, status: :accepted)
  rescue
    raise ActiveRecord::Rollback
  end

  alias_attribute :author, :user

  has_many :join_requests, as: :joinable, dependent: :destroy
  has_many :members, -> {
    where("join_requests.status = 'accepted'")
    # .order("neighborhoods.user_id = join_requests.user_id")
    # .order("users.first_name")
  }, through: :join_requests, source: :user
  has_many :neighborhoods_entourages

  has_many :outings, -> { where(group_type: :outing) }, through: :neighborhoods_entourages, source: :entourage

  reverse_geocoded_by :latitude, :longitude
  has_many :chat_messages, as: :messageable, dependent: :destroy

  validates_presence_of [:status, :name, :description, :latitude, :longitude]

  alias_attribute :title, :name

  # valides :image_url # should be 390x258 (2/3)
  attr_accessor :neighborhood_image_id

  default_scope { where(status: :active) }

  scope :with_moderation_area, -> (moderation_area) {
    if moderation_area == :hors_zone
      return where("left(postal_code, 2) not in ?", ModerationArea.only_departements)
    end

    where("left(postal_code, 2) = ?", ModerationArea.departement(moderation_area))
  }

  scope :search_by, ->(search) {
    strip = search && search.strip
    like = "%#{strip}%"

    where(%(
      neighborhoods.id = :id OR
      trim(name) ILIKE :name OR
      trim(description) ILIKE :description
    ), {
      id: strip.to_i,
      name: like,
      description: like
    })
  }

  scope :inside_perimeter, -> (latitude, longitude, travel_distance) {
    if latitude && longitude
      where("#{PostgisHelper.distance_from(latitude, longitude, :neighborhoods)} < ?", travel_distance)
    end
  }
  scope :order_by_distance_from, -> (latitude, longitude) {
    if latitude && longitude
      order(PostgisHelper.distance_from(latitude, longitude, :neighborhoods))
    end
  }
  scope :order_by_activity, -> {
    # Groupe actif = au moins 1 message ou 1 événement créé par semaine pendant 1 mois ou plus
    # Code proposé : classé par nombre d'événements puis nombre de messages dans le mois
    order_by_outings.order_by_chat_messages
  }
  scope :order_by_outings, -> {
    left_outer_joins(:outings).group('neighborhoods.id').order(%(
      sum(
        case
          (entourages.metadata->>'starts_at')::date > date_trunc('day', NOW() - interval '1 month')
        when true then 1
        else 0
        end
      ) desc
    ))
  }
  scope :order_by_chat_messages, -> {
    left_outer_joins(:chat_messages).group('neighborhoods.id').order(%(
      sum(
        case
          chat_messages.created_at > date_trunc('day', NOW() - interval '1 month')
        when true then 1
        else 0
        end
      ) desc
    ))
  }
  scope :like, -> (search) {
    return unless search.present?

    where('(unaccent(neighborhoods.name) ilike unaccent(:name) or unaccent(neighborhoods.description) ilike unaccent(:description))', {
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

  def active?
    status.to_sym == :active
  end

  def interests= interests
    unless interests.compact.map(&:to_sym).include?(:other)
      self[:other_interest] = nil
    end

    super(interests)
  end

  def google_place_id= google_place_id
    super(google_place_id)

    return unless google_place_id.present?

    google_place_details = UserServices::AddressService.get_google_place_details(google_place_id)

    self[:place_name] = google_place_details[:place_name]
    self[:street_address] = google_place_details[:formatted_address]
    self[:postal_code] = google_place_details[:postal_code]
    self[:latitude] = google_place_details[:latitude]
    self[:longitude] = google_place_details[:longitude]
  end

  def place_name= place_name
    return if google_place_id_changed? && google_place_id.present?

    self[:google_place_id] = nil

    super(place_name)
  end

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
    outings.where("metadata->>'starts_at' <= ?", Time.zone.now).where("metadata->>'ends_at' >= ?", Time.zone.now)
  end

  def has_ongoing_outing?
    ongoing_outings.any?
  end

  def parent_chat_messages
    chat_messages.where(ancestry: nil)
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
