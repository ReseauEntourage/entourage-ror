#Solution taken from : http://gis.stackexchange.com/a/25883
module EntourageServices
  class EntourageLocationRandomizer
    RANDOM_RADIUS=125.0

    def initialize(entourage:)
      @entourage = entourage
    end

    def random_longitude
      return entourage.longitude if Rails.env.test?
      entourage.longitude + (w * Math.cos(t))
    end

    def random_latitude
      return entourage.latitude if Rails.env.test?
      entourage.latitude + (w * Math.sin(t))
    end

    private
    attr_reader :entourage

    def w
      radius * Math.sqrt(rand)
    end

    def t
      2 * Math::PI * rand
    end

    #Convert radius from meters to degrees
    def radius
      RANDOM_RADIUS / 111300
    end
  end
end