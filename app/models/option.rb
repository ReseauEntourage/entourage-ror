class Option < ApplicationRecord
  validates_presence_of :key

  def self.active? key
    return false unless option = Option.find_by_key(key)

    option.active?
  end
end
