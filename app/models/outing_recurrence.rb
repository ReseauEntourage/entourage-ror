class OutingRecurrence < ApplicationRecord
  AVAILABLE_RECURRENCES = 5

  has_many :outings, foreign_key: :recurrency_identifier, primary_key: :identifier

  after_initialize :set_identifier, if: :new_record?

  validates_inclusion_of :recurrency, in: [0, 7, 15, 31], allow_nil: true

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
    outings.active.future.count < AVAILABLE_RECURRENCES
  end

  def generate
    return unless continue
    return unless last_outing.present?

    last_outing.dup
  end

  def last_outing
    @last_outing ||= Outing.where(recurrency_identifier: identifier).last
  end
end
