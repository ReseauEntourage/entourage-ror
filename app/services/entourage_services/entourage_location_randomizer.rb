#Solution taken from : http://gis.stackexchange.com/a/25883
module EntourageServices
  class EntourageLocationRandomizer
    RANDOM_RADIUS=250.0

    def initialize(entourage:)
      @entourage = entourage
    end

    def random_longitude
      entourage.longitude + (w * Math.cos(t))
    end

    def random_latitude
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
      RANDOM_RADIUS / 111300;
    end
  end
end