class Neighborhood < ApplicationRecord
  include Interestable
  include CoordinatesScopable
  include JoinableScopable
  include Recommandable
  include ModeratorReadable
  include Deeplinkable
  include Experimental::NeighborhoodSlack::Callback

  after_validation :track_status_change

  STATUSES = [:active, :deleted, :blacklisted]

  belongs_to :user

  after_create do |neighborhood|
    JoinRequest.create!(role: :creator, joinable: neighborhood, user: neighborhood.user, status: :accepted)
  rescue
    raise ActiveRecord::Rollback
  end

  alias_attribute :author, :user

  has_many :members, -> {
    where("join_requests.status = 'accepted'").order("join_requests.role, users.first_name")
  }, through: :join_requests, source: :user
  has_many :neighborhoods_entourages
  has_many :chat_messages, as: :messageable, dependent: :destroy
  has_many :parent_chat_messages, -> { where(ancestry: nil) }, as: :messageable, class_name: :ChatMessage
  has_many :conversation_messages, as: :messageable, dependent: :destroy

  # outings
  has_many :outings, -> {
    where(group_type: :outing).active
  }, through: :neighborhoods_entourages, source: :entourage, class_name: :Outing

  has_many :past_outings, -> {
    where(group_type: :outing).active
    .where("metadata->>'ends_at' < ?", Time.zone.now)
  }, through: :neighborhoods_entourages, source: :entourage, class_name: :Outing

  has_many :future_outings, -> {
    where(group_type: :outing).active
    .where("metadata->>'ends_at' > ?", Time.zone.now)
  }, through: :neighborhoods_entourages, source: :entourage, class_name: :Outing

  has_many :ongoing_outings, -> {
    where(group_type: :outing).active
    .where("metadata->>'starts_at' <= ?", Time.zone.now)
    .where("metadata->>'ends_at' >= ?", Time.zone.now)
  }, through: :neighborhoods_entourages, source: :entourage, class_name: :Outing

  reverse_geocoded_by :latitude, :longitude

  validates_presence_of [:status, :name, :description, :latitude, :longitude]

  alias_attribute :title, :name
  alias_attribute :posts, :parent_chat_messages

  # valides :image_url # should be 390x258 (2/3)
  attr_accessor :neighborhood_image_id
  attr_accessor :change_ownership_message

  default_scope { where(status: :active) }

  scope :active, -> { where(status: :active) }
  scope :public_only, -> { where(public: true) }

  scope :with_moderation_area, -> (moderation_area) {
    if moderation_area.present? && moderation_area.to_sym == :hors_zone
      return where("left(postal_code, 2) not in (?)", ModerationArea.only_departements).or(
        where.not(country: :FR)
      )
    end

    where("left(postal_code, 2) = ?", ModerationArea.departement(moderation_area)).where(country: :FR)
  }

  scope :join_chat_message_with_images, -> {
    joins(%(
      left join (
        select #{table_name}.id
        from #{table_name}
        left join chat_messages as chat_message_with_images on
          chat_message_with_images.messageable_id = #{table_name}.id and
          chat_message_with_images.messageable_type = '#{self.name}'
        where
          chat_message_with_images.image_url is not null
        group by #{table_name}.id
      ) as #{table_name}_imageable on
        #{table_name}_imageable.id = #{table_name}.id
    ))
  }

  scope :join_chat_messages_on_max_created_at, -> {
    joins(%(
      left join (
        select
          #{table_name}.id,
          max(chat_message_on_max_created_at.created_at) as max_created_at
        from #{table_name}
        left join chat_messages as chat_message_on_max_created_at on
          chat_message_on_max_created_at.messageable_id = #{table_name}.id and
          chat_message_on_max_created_at.messageable_type = '#{self.name}'
        group by #{table_name}.id
      ) as #{table_name}_messageable on
        #{table_name}_messageable.id = #{table_name}.id
    ))
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

  scope :recommandable, -> { self.active.public_only }

  def active?
    status.to_sym == :active
  end

  def deleted?
    status.to_sym == :deleted
  end

  def blacklisted?
    status.to_sym == :blacklisted
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
    self[:country] = google_place_details[:country]
    self[:latitude] = google_place_details[:latitude]
    self[:longitude] = google_place_details[:longitude]
  end

  def place_name= place_name
    return if google_place_id_changed? && google_place_id.present?

    self[:google_place_id] = nil

    super(place_name)
  end

  def display_address= display_address
    return unless display_address.present?
    return unless latitude.present? && longitude.present?
    return if google_place_id_changed? && google_place_id.present?

    return unless google_place_details = UserServices::AddressService.get_google_place_details_from_coordinates(latitude, longitude)

    self[:place_name] = google_place_details[:place_name]
    self[:street_address] = google_place_details[:formatted_address]
    self[:postal_code] = google_place_details[:postal_code]
    self[:latitude] = google_place_details[:latitude]
    self[:longitude] = google_place_details[:longitude]
  end

  def posts_count
    posts.length
  end

  def outings_with_admin_online scope: :outings
    scope = :outings unless [:past_outings, :future_outings, :ongoing_outings].include?(scope)

    onlines = Outing.unscope(:order).where(online: true)
    onlines = onlines.future if scope == :future_outings
    onlines = onlines.past if scope == :past_outings
    onlines = onlines.ongoing if scope == :ongoing_outings

    Outing.unscope(:order).where(
      id: send(scope).select(:id)
    ).or(onlines.where(user: User.where(admin: true)))
  end

  def past_outings_count
    past_outings.length
  end

  def future_outings_count
    future_outings.length
  end

  def has_ongoing_outing?
    ongoing_outings.any?
  end

  def unread_count_chat_messages_for user
    JoinRequest
      .where(user: user, joinable: self)
      .with_unread_messages
      .count
  end

  def unread_images_count_chat_messages_for user
    JoinRequest
      .where(user: user, joinable: self)
      .with_unread_images_messages
      .count
  end

  def unread_first_chat_message_for user
    JoinRequest
      .select("join_requests.id, join_requests.created_at, min(chat_messages.id) as unread_first_chat_message_id")
      .where(user: user, joinable: self)
      .with_unread_messages
      .group('join_requests.id')
      .first
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

  def image_url_with_size size
    return unless self['image_url'].present?

    NeighborhoodImage.image_url_for_with_size(self['image_url'], size)
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

  private

  def track_status_change
    self[:status_changed_at] = Time.zone.now if status_changed?
  end
end
