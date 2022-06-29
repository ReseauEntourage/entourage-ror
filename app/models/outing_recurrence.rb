class OutingRecurrence < ApplicationRecord
  after_initialize :set_identifier, if: :new_record?

  def set_identifier
    self.identifier ||= SecureRandom.hex(8)
  end
end
