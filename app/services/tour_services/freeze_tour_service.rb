module TourServices
  class FreezeTourService
    def initialize(tour: tour)
      @tour = tour
    end

    def freeze!
      return unless tour.closed?

      tour.status = :freezed
      tour.save
    end

    private
    attr_reader :tour
  end
end