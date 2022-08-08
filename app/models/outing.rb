class Outing < Entourage
  include Interestable
  include JsonStorable # @caution delete this include as soon as we migrate Rails to 6 or higher

  store_accessor :metadata, :starts_at, :ends_at, :previous_at, :place_name, :street_address, :google_place_id, :display_address, :landscape_url, :landscape_thumbnail_url, :portrait_url, :portrait_thumbnail_url, :place_limit

  after_initialize :set_outing_recurrence, if: :recurrency

  before_validation :update_relatives_dates, if: :force_relatives_dates
  before_validation :cancel_outing_recurrence, unless: :new_record?
  before_validation :set_entourage_image_id

  after_validation :add_creator_as_member, if: :new_record?
  after_validation :dup_neighborhoods_entourages, if: :original_outing
  after_validation :dup_taggings, if: :original_outing

  has_many :members, -> { where("join_requests.status = 'accepted'") }, through: :join_requests, source: :user
  has_many :neighborhoods_entourages, foreign_key: :entourage_id
  has_many :neighborhoods, through: :neighborhoods_entourages

  # siblings and relatives
  has_many :siblings, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  has_many :relatives, -> (object) {
    where.not(id: object.id)
  }, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  # future_siblings and future_relatives
  has_many :future_siblings, -> {
    where("metadata->>'starts_at' >= ?", DateTime.now)
  }, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  has_many :future_relatives, -> (object) {
    where.not(id: object.id).where("metadata->>'starts_at' >= ?", DateTime.now)
  }, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  belongs_to :recurrence, class_name: :OutingRecurrence, foreign_key: :recurrency_identifier, primary_key: :identifier

  accepts_nested_attributes_for :recurrence, :future_siblings, :future_relatives

  validate :validate_neighborhood_ids
  validate :validate_member_ids, unless: :new_record?

  default_scope { where(group_type: :outing).order(Arel.sql("metadata->>'starts_at'")) }

  scope :future, -> { where("metadata->>'starts_at' >= ?", Time.zone.now) }

  attr_accessor :recurrency, :original_outing, :force_relatives_dates

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
      errors.add(:user_id, "User has to be a member of outing")
    end
  end

  def interests= interests
    unless interests.compact.map(&:to_sym).include?(:other)
      self[:other_interest] = nil
    end

    super(interests)
  end

  def parent_chat_messages
    chat_messages.where(ancestry: nil)
  end

  # inbetween occurrences are created whenever we change an active recurrence from 14 to 7
  def create_inbetween_occurrences?
    return unless recurrence.present?

    recurrency&.to_i == 7 && recurrence.recurrency&.to_i == 14
  end

  def create_inbetween_occurrences!
    recurrence.update_attribute(:recurrency, recurrency)

    future_sibling_ids.each do |outing_id|
      # @caution .dup clones by reference the original outing
      # To avoid to modify source and duplication at the same time, we do not iterate on future_siblings objects
      future_siblings << Outing.find(outing_id).dup
    end
  end

  # we cancel odd occurrences whenever we change an active recurrence from 7 to 14
  def cancel_odds_occurrences?
    return unless recurrence.present?

    recurrency&.to_i == 14 && recurrence.recurrency&.to_i == 7
  end

  def cancel_odds_occurrences!
    recurrence.update_attribute(:recurrency, recurrency)

    future_siblings.each_with_index do |outing, index|
      next if index.even?

      outing.assign_attributes(status: :cancelled)
    end
  end

  # we update relatives dates whenever an outing update its dates with "force_relatives_dates" option
  def update_relatives_dates
    return if new_record?
    return unless force_relatives_dates
    return unless starts_at_changed? || ends_at_changed?
    return unless recurrence.present?
    return unless future_relatives.any?

    future_relatives.each do |outing|
      outing.assign_attributes(metadata: outing.metadata.merge({
        starts_at: outing.metadata[:starts_at] + (self.metadata[:starts_at] - starts_at_was),
        ends_at: outing.metadata[:ends_at] + (self.metadata[:ends_at] - ends_at_was)
      }))
    end
  end

  # we create recurrence relationship whenever we set a recurrency to an outing that does not already defines this relationship
  def set_outing_recurrence
    return if recurrence.present?
    return if recurrency.blank?

    self.recurrence = OutingRecurrence.new(recurrency: recurrency, continue: true)
    self.recurrency_identifier = self.recurrence.identifier
  end

  def cancel_outing_recurrence
    return if recurrency.blank?
    return unless recurrence.present?
    return unless recurrency&.to_i == 0

    self.recurrence.assign_attributes(continue: false)
  end

  def add_creator_as_member
    return unless user.present?
    return if join_requests.map(&:user_id).include?(user.id)

    join_requests << JoinRequest.new(user: user, joinable: self, status: :accepted, role: :organizer)
  end

  def dup_neighborhoods_entourages
    return unless original_outing
    return unless new_record?

    original_outing.neighborhoods_entourages.each do |neighborhood_entourage|
      neighborhoods_entourages << NeighborhoodsEntourage.new(neighborhood: neighborhood_entourage.neighborhood, entourage: self)
    end
  end

  def dup_taggings
    return unless original_outing
    return unless new_record?

    self.interests = original_outing.interest_list
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
