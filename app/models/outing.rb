class Outing < Entourage
  include Interestable
  include SfCategorizable
  include JsonStorable # @caution delete this include as soon as we migrate Rails to 6 or higher
  include Recommandable

  RECENTLY_PAST_PERIOD = 7.days

  METADATA_ACCESSOR = [:starts_at, :ends_at, :previous_at, :place_name, :street_address, :google_place_id, :display_address, :landscape_url, :landscape_thumbnail_url, :portrait_url, :portrait_thumbnail_url, :place_limit]

  store_accessor :metadata, :starts_at, :ends_at, :previous_at, :place_name, :street_address, :google_place_id, :display_address, :landscape_url, :landscape_thumbnail_url, :portrait_url, :portrait_thumbnail_url, :place_limit

  after_save :generate_initial_recurrences, if: :recurrency

  before_validation :update_relatives_dates, if: :force_relatives_dates
  before_validation :cancel_outing_recurrence, unless: :new_record?
  before_validation :set_entourage_image_id
  before_validation :normalize_exclusive_to

  after_validation :add_creator_as_member, if: :new_record?
  after_validation :dup_neighborhoods_entourages, if: :original_outing
  after_validation :dup_taggings, if: :original_outing

  has_many :members, -> {
    where("join_requests.status = 'accepted'").order("join_requests.role, users.first_name")
  }, through: :join_requests, source: :user
  has_many :neighborhoods_entourages, foreign_key: :entourage_id
  has_many :neighborhoods, through: :neighborhoods_entourages

  # siblings and relatives
  has_many :siblings, -> {
    where.not(recurrency_identifier: nil)
  }, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  has_many :relatives, -> (object) {
    where.not(id: object.id).where.not(recurrency_identifier: nil)
  }, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  # future_siblings and future_relatives
  has_many :future_siblings, -> {
    where("metadata->>'starts_at' >= ?", Time.zone.now).where.not(recurrency_identifier: nil)
  }, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  has_many :future_relatives, -> (object) {
    where.not(id: object.id).where("metadata->>'starts_at' >= ?", Time.zone.now).where.not(recurrency_identifier: nil)
  }, class_name: :Outing, foreign_key: :recurrency_identifier, primary_key: :recurrency_identifier

  belongs_to :recurrence, class_name: :OutingRecurrence, foreign_key: :recurrency_identifier, primary_key: :identifier, required: false

  # chat_messages redefinitions without updated_status
  has_many :chat_messages, -> { where.not(message_type: :status_update) }, as: :messageable, dependent: :destroy
  has_one :last_chat_message, -> {
    select('DISTINCT ON (messageable_id, messageable_type) *').where.not(message_type: :status_update).order('messageable_id, messageable_type, created_at desc')
  }, as: :messageable, class_name: 'ChatMessage'
  has_one :chat_messages_count, -> {
    select('DISTINCT ON (messageable_id, messageable_type) COUNT(*), messageable_id, messageable_type').where.not(message_type: :status_update).group('messageable_id, messageable_type')
  }, as: :messageable, class_name: 'ChatMessage'

  accepts_nested_attributes_for :recurrence, :future_siblings, :future_relatives

  alias_attribute :accepted_members, :members

  validate :validate_outings_starts_at
  validate :validate_neighborhood_ids
  validate :validate_member_ids, unless: :new_record?
  validates_inclusion_of :exclusive_to, in: User::GOALS, allow_nil: true

  default_scope { where(group_type: :outing).order(Arel.sql("metadata->>'starts_at'")) }

  scope :future, -> { where("metadata->>'starts_at' >= ?", Time.zone.now) }
  scope :past, -> { where("metadata->>'starts_at' <= ?", Time.zone.now) }
  scope :ongoing, -> {
    where("metadata->>'starts_at' <= ?", Time.zone.now)
    .where("metadata->>'ends_at' >= ?", Time.zone.now)
  }
  scope :starting_after, -> (from) { where("metadata->>'starts_at' >= ?", from) }
  scope :ending_after, -> (from) { where("metadata->>'ends_at' >= ?", from) }
  scope :upcoming, -> (until_at) { where("metadata->>'starts_at' BETWEEN ? AND ?", Time.zone.now, until_at) }
  scope :between, -> (from, to) { where("metadata->>'starts_at' BETWEEN ? AND ?", from, to) }

  scope :recommandable, -> { self.active.future }
  scope :future_or_ongoing, -> { ending_after(Time.zone.now) }
  scope :future_or_recently_past, -> { ending_after(RECENTLY_PAST_PERIOD.ago) }
  scope :default_order, -> { order(Arel.sql("metadata->>'starts_at'")) }
  scope :reversed_order, -> { order(Arel.sql("metadata->>'starts_at' desc")) }

  scope :welcome_category, -> { where(online: true).tagged_with_sf_category([
    :atelier_femmes,
    :atelier_mdlr,
    :atelier_preca,
    :welcome_entourage_local
  ]) }

  scope :unlimited, -> { where("(metadata->>'place_limit' is null or metadata->>'place_limit' = '0' or metadata->>'place_limit' = '')") }

  scope :for_user, -> (user) {
    return unless user
    return if user.association?
    return if user.ambassador?

    return where("exclusive_to is null or exclusive_to = 'ask_for_help'") if user.is_ask_for_help?
    return where("exclusive_to is null or exclusive_to = 'offer_help'") if user.is_offer_help?

    where(exclusive_to: nil)
  }

  attr_accessor :recurrency, :original_outing, :force_relatives_dates, :preload_image_url, :preload_member_ids

  # hack that fixes not working store_accessor accessors
  METADATA_ACCESSOR.each do |metadata_accessor|
    define_method(metadata_accessor) do
      metadata[metadata_accessor]
    end
  end

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

  def validate_outings_starts_at
    return unless metadata[:starts_at].present?

    if metadata[:starts_at] < Time.now
      errors.add(:metadata, "'starts_at' must be in the future")
    end
  end

  def validate_neighborhood_ids
    return unless outing?
    return if user && user.admin?
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
  def recurrency= recurrency
    @recurrency = recurrency

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

  # @refactor might be moved to job
  def generate_initial_recurrences
    return if recurrency.blank?
    return if recurrency&.to_i == 0
    return unless self.recurrence.present?

    self.recurrence.generate_initial_recurrences
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
    self.sf_category = original_outing.sf_category
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

  def normalize_exclusive_to
    self.exclusive_to = nil if exclusive_to.blank?
  end

  def set_uuid!
    self.uuid = SecureRandom.uuid
    self.uuid_v2 = self.class.generate_uuid_v2
  end

  def place_limit?
    metadata[:place_limit].present? && metadata[:place_limit].to_i > 0
  end

  def city
    city_from_display_address || city_from_google_place_id
  end

  def city_from_display_address
    return if metadata[:display_address].blank?
    return unless matches = metadata[:display_address].match(/\b\d{5}\s+(.+)$/)

    matches[1]
  end

  def city_from_google_place_id
    return unless google_place_details = UserServices::AddressService.get_google_place_details(metadata[:google_place_id])
    return unless google_place_details.has_key?(:city)

    google_place_details[:city]
  rescue
  end

  class << self
    def bucket_name
      EntourageImage.storage.bucket_name
    end
  end
end
