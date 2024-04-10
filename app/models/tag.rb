class Tag < ApplicationRecord
  class << self
    def interest_list
      interests.keys.map(&:to_s)
    end

    def interests
      I18n.t('tags.interests')
    end

    def involvement_list
      involvements.keys.map(&:to_s)
    end

    def involvements
      I18n.t('tags.involvements')
    end

    def concern_list
      concerns.keys.map(&:to_s)
    end

    def concerns
      I18n.t('tags.concerns')
    end

    def section_list
      sections.keys.map(&:to_s)
    end

    def sections
      I18n.t('tags.sections')
    end

    def sections_collection
      I18n.t('tags.sections').map do |id, names|
        [id, names[:name]]
      end.to_h
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

    # these methods are mainly used for Entourage instances that does not extend Interestable or Sectionable
    def section_list_for record
      tags_for_context_and_taggable(context: :sections, taggable: record)
    end

    def interest_list_for record
      tags_for_context_and_taggable(context: :interests, taggable: record)
    end

    def involvement_list_for record
      tags_for_context_and_taggable(context: :involvements, taggable: record)
    end

    def concern_list_for record
      tags_for_context_and_taggable(context: :concerns, taggable: record)
    end

    private
      def tags_for_context_and_taggable context:, taggable:
        ActsAsTaggableOn::Tag.joins(:taggings).where(taggings: { context: context, taggable: taggable }).pluck(:name)
      end
  end
end
