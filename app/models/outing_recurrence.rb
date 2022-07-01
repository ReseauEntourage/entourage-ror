class OutingRecurrence < ApplicationRecord
  after_initialize :set_identifier, if: :new_record?

  def set_identifier
    self.identifier ||= SecureRandom.hex(8)
  end

  def new_outing
    return unless last_outing.present?

    last_outing.dup
  end

  def last_outing
    @last_outing ||= Outing.where(recurrency_identifier: identifier).order_by_starts_at.last
  end
end
