module NeighborhoodServices
  class Helper
    attr_reader :record

    def initialize record
      @record = record
    end

    def main_departement_slug
      return unless record.neighborhoods.any?

      departements = ModerationArea.pluck(:departement)

      neighborhood_departements = record.neighborhoods.map do |neighborhood|
        next unless neighborhood.postal_code

        (departements & [neighborhood.postal_code[0..1]] | [ModerationArea::HORS_ZONE]).first
      end

      main_departement = neighborhood_departements.max_by do |area|
        neighborhood_departements.count(area)
      end

      ModerationArea.departement_slug(main_departement)
    end
  end
end
