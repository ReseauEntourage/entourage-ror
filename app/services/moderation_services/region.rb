module ModerationServices
  class Region
    DEPARTMENTS_IN_REGION = {
      # sud_ouest: nouvelle aquitaine, occitanie
      sud_ouest: %w{ 16 17 19 23 24 33 40 47 64 79 86 87 09 11 12 30 31 32 34 46 48 65 66 81 82 },

      # sud_est: paca, corse
      sud_est: %w{ 04 05 06 13 83 84 2A 2B 38 42 69 01 03 07 15 26 43 63 73 74 },

      # grand_ouest: bretagne, pays de la loire, normandie
      grand_ouest: %w{ 22 29 35 56 44 49 53 72 85 14 27 50 61 76 },

      # centre: centre val de loire, bourgogne, grand est
      centre: %w{ 18 28 36 37 41 45 },

      # idf: idf
      idf: %w{ 75 77 78 91 92 93 94 95 },

      # hauts_de_france: hauts de france
      hauts_de_france: %w{ 02 59 60 62 80 },

      # grand_est: hauts de france
      grand_est: %w{ 08 10 51 52 54 55 57 67 68 88 21 25 58 70 71 89 90 39 },
    }.freeze

    RegionStruct = Struct.new(:id, :name, :departments) do
      def initialize id:, name:, departments:
        @id = id
        @name = name
        @departments = departments
      end

      def id
        @id
      end

      def name
        @name
      end

      def departements
        @departements
      end
    end

    def self.regions
      DEPARTMENTS_IN_REGION.keys.map do |region|
        RegionStruct.new(id: region, name: region_name(region), departments: departments_in(region))
      end
    end

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
