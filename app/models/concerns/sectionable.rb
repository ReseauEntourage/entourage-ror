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
    return unless section.present?

    self.section_list = [section]
  end

  def section_names
    # optimization to resolve n+1
    sections.map(&:name)
  end
end
