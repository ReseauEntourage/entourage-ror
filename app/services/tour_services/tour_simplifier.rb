# require 'cmath'

module TourServices
  class TourSimplifier
    R=6371.0

    def initialize(tour:)
      @tour = tour
    end

    def simplified_points
    end

    private
    attr_reader :tour
  end
end
