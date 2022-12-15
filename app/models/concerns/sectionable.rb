module Sectionable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :sections

    validate :validate_section_list!
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
    return if category_changed?

    self.category = ActionServices::Mapper.category_from_section(section)
  end

  def set_display_category_from_section section
    return if display_category_changed?

    self.display_category = ActionServices::Mapper.display_category_from_section(section)
  end
end
