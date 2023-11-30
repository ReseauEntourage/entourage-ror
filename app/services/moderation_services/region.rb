module ModerationServices
  class Region
    DEPARTMENTS_IN_REGION = {
      aura: %w{ 69 42 01 03 07 15 26 38 43 63 73 74 },
      bretagne: %w{ 35 56 44 22 53 29 85 },
      hdf: %w{ 59 62 60 80 02 },
      idf: %w{ 75 92 93 94 77 78 91 },
      paca: %w{ 13 05 83 06 84 04 },
      gironde: %w{ 33 },
      digital_community: (
        %w{ 08 10 51 52 54 55 57 67 68 88 } +
        %w{ 18 28 36 37 41 45 } +
        %w{ 21 25 39 58 70 71 89 } +
        %w{ 16 17 19 23 24 40 47 64 79 86 87 } +
        %w{ 09 11 12 32 46 65 66 81 82 31 34 30 } +
        %w{ 14 } +
        %w{ 49 72 }
      )
    }.freeze

    # def self.names
    #   DEPARTMENTS_IN_REGION.keys
    # end

    # def self.departments
    #   DEPARTMENTS_IN_REGION.values.flatten
    # end

    def self.departments_in region
      return unless region

      DEPARTMENTS_IN_REGION[region.to_sym]
    end

    def self.for_department department
      DEPARTMENTS_IN_REGION.select do |_, departments|
        departments.include?(department)
      end.keys.first
    end

    def self.region_name region
      return unless region
      I18n.t("regions.#{region}")
    end
  end
end
