class Tag < ApplicationRecord
  class << self
    def find_tag_for instance, context
      Tag.joins('INNER JOIN taggings ON tags.id = taggings.tag_id').where(taggings: { taggable_id: instance.id, taggable_type: 'Entourage', context: context })
    end

    # interest
    def interest_list
      interests.keys.map(&:to_s)
    end

    def interests
      I18n.t('tags.interests')
    end

    # category
    def category_list
      categories.keys.map(&:to_s)
    end

    def categories
      I18n.t('tags.categories')
    end

    # involvement
    def involvement_list
      involvements.keys.map(&:to_s)
    end

    def involvements
      I18n.t('tags.involvements')
    end

    # concern
    def concern_list
      concerns.keys.map(&:to_s)
    end

    def concerns
      I18n.t('tags.concerns')
    end

    # section
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

    # orientation
    def orientation_list
      orientations.keys.map(&:to_s)
    end

    def orientations
      I18n.t('tags.orientations')
    end

    def orientations_collection
      I18n.t('tags.orientations').map do |id, names|
        [id, names[:name]]
      end.to_h
    end

    # sf_category
    def sf_category_list
      sf_categories.keys.map(&:to_s)
    end

    def sf_categories
      I18n.t('tags.sf_categories')
    end

    # signal
    def signal_list
      signals.keys.map(&:to_s)
    end

    def signals
      I18n.t('tags.signals')
    end

    def signal_t signal
      I18n.t("tags.signals.#{signal}")
    end

    # these methods are mainly used for Entourage instances that does not extend Categorizable, Interestable or Sectionable
    def section_list_for record
      tags_for_context_and_taggable(context: :sections, taggable: record)
    end

    def orientation_list_for record
      tags_for_context_and_taggable(context: :orientations, taggable: record)
    end

    def interest_list_for record
      tags_for_context_and_taggable(context: :interests, taggable: record)
    end

    def category_list_for record
      tags_for_context_and_taggable(context: :categories, taggable: record)
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
