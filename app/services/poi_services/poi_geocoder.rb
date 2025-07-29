module PoiServices
  class PoiGeocoder
    def initialize(poi:, params:)
      @params = params
      @poi = poi
    end

    def geocode
      return poi if params['latitude'] && params['longitude']

      poi.adress = params['adress'] || params[:adress]
      poi.latitude = poi.longitude = nil

      if poi.geocode.nil?
        poi.errors.add(:base, "L'adresse ne peut pas être géocodé, merci de remplir les coordonnées à la main")
      end
      poi
    end

    private
    attr_reader :poi, :params
  end
end
