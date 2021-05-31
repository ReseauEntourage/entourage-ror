module PoiServices
  class Soliguide
    API_HOST = "https://entourage-soliguide-preprod.herokuapp.com/api/v1/pois"

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
    end

    def apply?
      return false unless EnvironmentHelper.env.in? [:development, :staging, :test]

      close_to?(PARIS) || close_to?(LYON)
    end

    def get_redirection
      params = {
        distance:  distance,
        latitude:  latitude,
        longitude: longitude,
      }

      params[:categories] = categories.first if categories.one?
      params[:query] = query if query.present?

      "#{PoiServices::Soliguide::API_HOST}?#{params.to_query}"
    end

    private
    attr_reader :latitude, :longitude, :distance, :category_ids, :query, :category_ids

    def categories
      @categories ||= (category_ids || "").split(",").map(&:to_i).uniq
    end

    def close_to? city
      # https://www.mapsdirections.info/en/measure-map-radius/?lat=45.75&lng=4.85&radius=5000
      x = city[:latitude] - latitude.to_f
      y = (city[:longitude] - longitude.to_f) * city[:coef]

      Math.sqrt(x**2 + y**2) * 110_250 <= city[:radius]
    end
  end
end
