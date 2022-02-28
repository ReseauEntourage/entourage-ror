class Tag < ApplicationRecord
  INTERESTS = %w(sport culture jardinage jeux)

  class << self
    def interest_list
      INTERESTS.sort
    end
  end
end
