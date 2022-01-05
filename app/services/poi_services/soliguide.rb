module PoiServices
  class Soliguide
    API_KEY = ENV['SOLIGUIDE_API_KEY']
    DISTANCE_MIN = 2
    DISTANCE_MAX = 10

    PARIS = {
      latitude: 48.8586,
      longitude: 2.3411,
      radius: 6000,
      coef: 0.65792 # Math.cos(48.8586 * Math::PI / 180)
    }

    LYON = {
      latitude: 45.75,
      longitude: 4.85,
      radius: 5000,
      coef: 0.69779 # Math.cos(45.75 * Math::PI / 180)
    }

    def initialize(params)
      @latitude = params[:latitude]
      @longitude = params[:longitude]
      @distance = params[:distance]
      @category_ids = params[:category_ids]
      @query = params[:query]
      @limit = params[:limit]
    end

    def apply?
      is_active? && close_to?(PARIS)
    end

    def is_active?
      Option.active? :soliguide
    end

    def query_params
      geoValue = if close_to?(PARIS)
        :Paris
      else
        :HorsZone
      end

      params = {
        location: {
          distance:  (distance || 0).to_f.clamp(DISTANCE_MIN, DISTANCE_MAX),
          latitude:  latitude,
          longitude: longitude,
          geoType: :ville,
          geoValue: geoValue,
        },
        options: {}
      }

      params[:categories] = soliguide_category(categories) if soliguide_category(categories).present?
      params[:name] = query if query.present?
      params[:options][:limit] = limit if limit.present?

      params
    end

    private
    attr_reader :latitude, :longitude, :distance, :category_ids, :query, :limit, :category_ids

    def categories
      @categories ||= (category_ids || "").split(",").map(&:to_i).uniq
    end

    def soliguide_category categories
      return unless categories.one?

      PoiServices::SoliguideFormatter::CATEGORIES_EQUIVALENTS_REVERSED[categories.first]
    end

    def close_to? city
      # https://www.mapsdirections.info/en/measure-map-radius/?lat=45.75&lng=4.85&radius=5000
      x = city[:latitude] - latitude.to_f
      y = (city[:longitude] - longitude.to_f) * city[:coef]

      Math.sqrt(x**2 + y**2) * 110_250 <= city[:radius]
    end
  end
end
