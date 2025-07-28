require 'geocoder/sql'

module FeedServices
  # lazily evaluates if the coordinates are inside one of the pre-defined areas
  # returns a String (name of the area or UNKNOWN_AREA)
  class FeedRequestArea < BasicObject
    # the areas are circles: lat,lng define the center, radius is in km
    # coeff is for the length of a degree of longitude depending on the latitude
    # area[:coeff] = Math.cos(area[:lat] * (::Math::PI / 180)).round(5)
    # see: http://jonisalonen.com/2014/computing-distance-between-coordinates-can-be-simple-and-fast/
    #
    # to plot: https://www.calcmaps.com/map-radius/
    AREAS = [
      { name: 'La Défense',           lat: 48.8918, lng:  2.2384, radius:  1.2, coeff: 0.65748 },
      { name: 'Clichy Levallois',     lat: 48.9,    lng:  2.2833, radius:  2.0, coeff: 0.65738 },
      { name: 'Marseille',            lat: 43.2967, lng:  5.3764, radius: 10.0, coeff: 0.72781 },
      { name: 'Toulouse',             lat: 43.6,    lng:  1.4333, radius: 10.0, coeff: 0.72417 },
      { name: 'Nice',                 lat: 43.7,    lng:  7.25,   radius: 10.0, coeff: 0.72297 },
      { name: 'Nantes',               lat: 47.2167, lng: -1.55,   radius: 10.0, coeff: 0.67923 },
      { name: 'Strasbourg',           lat: 48.5833, lng:  7.75,   radius: 10.0, coeff: 0.66153 },
      { name: 'Montpellier',          lat: 43.6,    lng:  3.8833, radius: 10.0, coeff: 0.72417 },
      { name: 'Bordeaux',             lat: 44.8333, lng: -0.5667, radius: 10.0, coeff: 0.70916 },
      { name: 'Lille',                lat: 50.6333, lng:  3.0667, radius: 10.0, coeff: 0.63428 },
      { name: 'Rennes',               lat: 48.0833, lng: -1.6833, radius: 10.0, coeff: 0.66805 },
      { name: 'Reims',                lat: 49.25,   lng:  4.0333, radius: 10.0, coeff: 0.65276 },
      { name: 'Le Havre',             lat: 49.5,    lng:  0.1333, radius: 10.0, coeff: 0.64945 },
      { name: 'Saint-Étienne',        lat: 45.4333, lng:  4.4,    radius: 10.0, coeff: 0.70174 },
      { name: 'Toulon',               lat: 43.1167, lng:  5.9333, radius: 10.0, coeff: 0.72996 },
      { name: 'Grenoble',             lat: 45.1667, lng:  5.7167, radius: 10.0, coeff: 0.70505 },
      { name: 'Dijon',                lat: 47.3167, lng:  5.0167, radius: 10.0, coeff: 0.67795 },
      { name: 'Angers',               lat: 47.4667, lng: -0.55,   radius: 10.0, coeff: 0.67602 },
      { name: 'Nîmes',                lat: 43.8333, lng:  4.35,   radius: 10.0, coeff: 0.72136 },
      { name: 'Aix-en-Provence',      lat: 43.5333, lng:  5.4333, radius: 10.0, coeff: 0.72497 },
      { name: 'Saint-Denis 93',       lat: 48.9333, lng:  2.3583, radius: 10.0, coeff: 0.65694 },
      { name: 'Versailles',           lat: 48.8,    lng:  2.1333, radius: 10.0, coeff: 0.65869 },
      { name: 'Boulogne-Billancourt', lat: 48.8333, lng:  2.25,   radius:  2.0, coeff: 0.65825 },
      { name: 'Nanterre',             lat: 48.9,    lng:  2.2,    radius:  2.0, coeff: 0.65738 },
      { name: 'Courbevoie',           lat: 48.8973, lng:  2.2522, radius:  2.0, coeff: 0.65741 },
      { name: 'Antony',               lat: 48.75,   lng:  2.3,    radius:  5.0, coeff: 0.65935 },
      { name: 'Lyon Ouest',           lat: 45.7725, lng:  4.8158, radius:  5.0, coeff: 0.69768 },
      { name: 'Lyon Est',             lat: 45.7470, lng:  4.8550, radius:  5.0, coeff: 0.69768 },
      { name: 'Paris République',     lat: 48.8661, lng:  2.3565, radius:  3.0, coeff: 0.65782 },
      { name: 'Paris 17 et 9',        lat: 48.8818, lng:  2.314,  radius:  3.0, coeff: 0.65761 },
      { name: 'Paris 15',             lat: 48.8426, lng:  2.2812, radius:  3.0, coeff: 0.65813 },
      { name: 'Paris 5',              lat: 48.8593, lng:  2.3266, radius:  3.0, coeff: 0.65791 },
      { name: 'Paris',                lat: 48.8593, lng:  2.3522, radius: 20.0, coeff: 0.65791 },
      { name: 'Lyon',                 lat: 45.7602, lng:  4.8521, radius: 20.0, coeff: 0.69766 },
    ]
    UNKNOWN_AREA = 'UNKNOWN_AREA'.freeze
    KM_PER_DEG = 110.25

    def initialize lat, lng
      @lat = lat
      @lng = lng
      @evaluated = false
    end

    def method_missing(method_name, *, &)
      _area.send(method_name, *, &)
    end

    def == other
      _area == other
    end

    def to_str
      _area
    end

    def present?
      _area != UNKNOWN_AREA
    end

    def blank?; !present?; end
    def empty?; !present?; end
    def !;      !present?; end

    private

    def respond_to_missing? method_name, include_private=false
      _area.send(:respond_to_missing?, method_name, include_private)
    end

    def _area
      @area ||= begin
        @lat = @lat.to_f
        @lng = @lng.to_f
        area, distance = AREAS
          .map { |a| [a, _distance(a[:lat], a[:lng], a[:coeff])] }
          .sort_by { |_, distance| distance }
          .first

        if area.nil? || distance > area[:radius]
          UNKNOWN_AREA
        else
          area[:name]
        end
      end
    end

    def _distance(lat, lng, coeff)
      x = @lat - lat
      y = (@lng - lng) * coeff
      KM_PER_DEG * ::Math.sqrt(x**2 + y**2)
    end
  end
end