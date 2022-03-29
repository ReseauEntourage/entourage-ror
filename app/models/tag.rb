class Tag < ApplicationRecord
  class << self
    def interest_list
      interests.keys.map(&:to_s)
    end

    def interests
      I18n.t('tags.interests')
    end

    def signal_list
      signals.keys.map(&:to_s)
    end

    def signals
      I18n.t('tags.signals')
    end
  end
end
