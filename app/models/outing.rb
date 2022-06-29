class Outing < Entourage
  include Interestable

  after_initialize :set_outing_recurrence, if: :new_record?
  before_validation :set_entourage_image_id

  belongs_to :recurrence, class_name: :OutingRecurrence, foreign_key: :recurrency_identifier, primary_key: :identifier

  validate :validate_neighborhood_ids

  default_scope { where(group_type: :outing) }

  scope :order_by_starts_at, -> {
    order("metadata->>'starts_at'")
  }

  attr_accessor :recurrency

  def validate_neighborhood_ids
    return unless outing?
    return if neighborhood_ids.empty?

    if (neighborhood_ids - user.neighborhood_participation_ids).any?
      errors.add(:neighborhood_ids, "User has to be a member of every neighborhoods")
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
end
