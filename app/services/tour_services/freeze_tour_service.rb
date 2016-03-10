module TourServices
  class FreezeTourService
    def initialize(tour:, user:)
      @tour = tour
      @user = user
    end

    def freeze!
      return unless user == tour.user
      return unless tour.closed?

      tour.status = :freezed
      tour.save
    end

    private
    attr_reader :tour, :user
  end
end