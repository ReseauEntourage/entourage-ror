class Outing < Entourage
  include Interestable

  after_initialize :set_outing_recurrence, if: :new_record?

  before_validation :set_entourage_image_id
  after_validation :add_creator_as_member, if: :new_record?
  after_validation :dup_neighborhoods_entourages, if: :new_record?

  has_many :neighborhoods_entourages, foreign_key: :entourage_id
  has_many :neighborhoods, through: :neighborhoods_entourages
  has_many :siblings, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier
  has_many :future_siblings, -> { where(group_type: :outing) }, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  belongs_to :recurrence, class_name: :OutingRecurrence, foreign_key: :recurrency_identifier, primary_key: :identifier

  validate :validate_neighborhood_ids
  validate :validate_member_ids, unless: :new_record?

  default_scope { where(group_type: :outing) }

  scope :order_by_starts_at, -> {
    order("metadata->>'starts_at'")
  }

  scope :future, -> { where("metadata->>'starts_at' >= ?", Time.zone.now) }

  attr_accessor :recurrency, :original_outing

  def initialize_dup original_outing
    set_uuid!

    self.original_outing = original_outing

    return super unless recurrency = recurrence&.recurrency
    return super unless last_outing = recurrence&.last_outing

    diff = recurrency == 31 ? 1.month : recurrency.days

    self.metadata[:starts_at] = last_outing.metadata[:starts_at] + diff
    self.metadata[:ends_at] = last_outing.metadata[:ends_at] + diff

    super
  end

  def validate_neighborhood_ids
    return unless outing?
    return if neighborhood_ids.empty?

    if (neighborhood_ids - user.neighborhood_participation_ids).any?
      errors.add(:neighborhood_ids, "User has to be a member of every neighborhoods")
    end
  end

  def validate_member_ids
    return unless outing?

    unless accepted_member_ids.include?(user_id)
      errors.add(:neighborhood_ids, "User has to be a member of outing")
    end
  end

  def interests= interests
    unless interests.compact.map(&:to_sym).include?(:other)
      self[:other_interest] = nil
    end

    super(interests)
  end

  def set_outing_recurrence
    return unless recurrency.present?

    self.recurrence = OutingRecurrence.new(recurrency: recurrency, continue: true)
    self.recurrency_identifier = self.recurrence.identifier
  end

  def add_creator_as_member
    return unless user.present?
    return if join_requests.map(&:user_id).include?(user.id)

    join_requests << JoinRequest.new(user: user, joinable: self, status: :accepted, role: :organizer)
  end

  def dup_neighborhoods_entourages
    return unless original_outing

    original_outing.neighborhoods_entourages.each do |neighborhood_entourage|
      neighborhoods_entourages << NeighborhoodsEntourage.new(neighborhood: neighborhood_entourage.neighborhood, entourage: self)
    end
  end

  def set_entourage_image_id
    return unless entourage_image_id.present?

    if entourage_image = EntourageImage.find_by_id(entourage_image_id)
      self.metadata[:landscape_url] = entourage_image[:landscape_url]
      self.metadata[:landscape_thumbnail_url] = entourage_image[:landscape_thumbnail_url]
      self.metadata[:portrait_url] = entourage_image[:portrait_url]
      self.metadata[:portrait_thumbnail_url] = entourage_image[:portrait_thumbnail_url]
    else
      remove_entourage_image_id!
    end
  end

  def set_uuid!
    self.uuid = SecureRandom.uuid
    self.uuid_v2 = self.class.generate_uuid_v2
  end
end
