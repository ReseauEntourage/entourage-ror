class Tag < ApplicationRecord
  class << self
    def interest_list
      interests.keys.map(&:to_s)
    end

    def interests
      I18n.t('tags')
    end
  end
end
