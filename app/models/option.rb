class Option < ApplicationRecord
  validates_presence_of :key

  class << self
    def active? key
      return false unless option = Option.find_by_key(key)

      option.active?
    end

    def soliguide_active?
      active?(:soliguide)
    end
  end
end
