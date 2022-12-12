module ActionServices
  class Mapper
    class << self
      DISPLAY_CATEGORY_MAPPING = {
        social: "social",
        resource: "services",
        mat_help: "equipment",
        other: "services"
      }
      SECTION_MAPPING = {
        social: "social",
        services: "resource",
        clothes: "mat_help",
        equipment: "mat_help",
        hygiene: "mat_help"
      }

      def section_from_display_category display_category
        return unless display_category
        return unless DISPLAY_CATEGORY_MAPPING.keys.include?(display_category.to_sym)

        DISPLAY_CATEGORY_MAPPING[display_category.to_sym]
      end

      def display_category_from_section section
        return unless section
        return unless SECTION_MAPPING.keys.include?(section.to_sym)

        SECTION_MAPPING[section.to_sym]
      end
    end
  end
end
