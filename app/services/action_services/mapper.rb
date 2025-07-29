module ActionServices
  class Mapper
    class << self
      DEFAULT_DISPLAY_CATEGORY = 'social'

      DISPLAY_CATEGORY_MAPPING = {
        social: 'social',
        resource: 'services',
        mat_help: 'equipment',
        other: 'services'
      }
      SECTION_MAPPING = {
        social: 'social',
        services: 'resource',
        clothes: 'mat_help',
        equipment: 'mat_help',
        hygiene: 'mat_help'
      }

      def section_from_display_category display_category
        return unless display_category
        return unless DISPLAY_CATEGORY_MAPPING.keys.include?(display_category.to_sym)

        DISPLAY_CATEGORY_MAPPING[display_category.to_sym]
      end

      def display_category_from_section section
        return DEFAULT_DISPLAY_CATEGORY unless section
        return DEFAULT_DISPLAY_CATEGORY unless SECTION_MAPPING.keys.include?(section.to_sym)

        SECTION_MAPPING[section.to_sym]
      end

      def display_categories_from_sections sections
        sections.map do |section|
          display_category_from_section(section)
        end
      end

      def category_from_section section
        display_category = display_category_from_section(section)

        return 'mat_help' if display_category == 'resource'

        display_category
      end
    end
  end
end
