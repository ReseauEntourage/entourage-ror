class OutingRecurrence < ApplicationRecord
  AVAILABLE_RECURRENCES = 5

  has_many :outings, foreign_key: :recurrency_identifier, primary_key: :identifier

  after_initialize :set_identifier, if: :new_record?

  validates_inclusion_of :recurrency, in: [7, 14, 31]

  default_scope { where(continue: true) }

  class << self
    def generate_all
      OutingRecurrence.find_in_batches do |outing_recurrences|
        outing_recurrences.each do |outing_recurrence|
          next unless outing_recurrence.generate_available?

          outing_recurrence.generate.save
        end
      end
    end
  end

  def set_identifier
    self.identifier ||= SecureRandom.hex(8)
  end

  def generate_available?
    return false unless continue
    return false unless last_outing.present?

    outings.active.future.count < AVAILABLE_RECURRENCES
  end

  def generate_initial_recurrences
    AVAILABLE_RECURRENCES.times do |time|
      return unless generate_available?

      generate.save!
    end
  end

  def generate
    last_outing.dup
  end

  def last_outing
    # @reminder default_scope is on metadata->>'starts_at'
    Outing
      .where(recurrency_identifier: identifier, status: :open)
      .where.not(status: [:blacklisted, :suspended])
      .last
  end
end
