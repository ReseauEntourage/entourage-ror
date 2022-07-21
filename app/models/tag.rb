class Tag < ApplicationRecord
  class << self
    def interest_list
      interests.keys.map(&:to_s)
    end

    def interests
      I18n.t('tags.interests')
    end

    def section_list
      sections.keys.map(&:to_s)
    end

    def sections
      I18n.t('tags.sections')
    end

    def signal_list
      signals.keys.map(&:to_s)
    end

    def signals
      I18n.t('tags.signals')
    end

    def signal_t signal
      I18n.t("tags.signals.#{signal}")
    end
  end
end
