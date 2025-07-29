module Sectionable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :sections

    validate :validate_section_list!

    scope :join_sections, -> {
      joins(sanitize_sql_array [%(
        left join taggings on taggable_type = '%s' and taggable_id = %s.id and context = 'sections'
        left join tags on tags.id = taggings.tag_id
      ), self.table_name.singularize.camelize, self.table_name])
    }

    # hack to prevent ActsAsTaggableOn::Taggable::TaggedWithQuery::AnyTagsQuery "select", "order" and "readonly"
    # this hack is required to chain with "or" statement
    scope :tagged_with_any_sections, -> (sections) {
      tagged_with(sections, any: true).unscope(:select, :order, :readonly)
    }

    scope :with_sections, -> (sections) {
      return tagged_with_any_sections(sections) unless attribute_names.include?("display_category")

      tagged_with_any_sections(sections).or(
        unscope(:order).where(display_category: ActionServices::Mapper.display_categories_from_sections(sections))
      )
    }

    scope :match_at_least_one_section, -> (section_list) {
      return unless section_list
      return unless section_list.any?

      join_sections.where("tags.name IN (?)", section_list)
    }
  end

  def validate_section_list!
    wrongs = self.section_list.reject do |section|
      Tag.section_list.include?(section)
    end

    errors.add(:sections, "#{wrongs.join(', ')} n'est pas inclus dans la liste") if wrongs.any?
  end

  def section
    self.section_names.first
  end

  def section= section
    set_category_from_section(section)
    set_display_category_from_section(section)

    return unless section.present?

    self.section_list = [section]
  end

  def section_names
    # optimization to resolve n+1
    sections.map(&:name)
  end

  private

  def set_category_from_section section
    return unless has_attribute?(:category)
    return if category_changed?

    self.category = ActionServices::Mapper.category_from_section(section)
  end

  def set_display_category_from_section section
    return unless has_attribute?(:display_category)
    return if display_category_changed?

    self.display_category = ActionServices::Mapper.display_category_from_section(section)
  end
end
