module TourServices
  class FakeTour
    def initialize(user:)
      @user = user
    end

    def create_tour!(status:)
      params = {tour_type: "medical",
                vehicle_type: "feet",
                status: status}
      tour = TourServices::TourBuilder.new(params: params, user: user).create
      create_tour_points(tour)
      SimplifyTourPointsJob.perform_later(tour.id)
    end

    def create_tour_points(tour)
      TourPoint.create!(latitude: 48.8737672, longitude: 2.32717019999996, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8688679, longitude: 2.35631139999998, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8688859, longitude: 2.36256309999999, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8720171, longitude: 2.35983699999997, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8757789, longitude: 2.36019269999997, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8765169, longitude: 2.35616989999994, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8763487, longitude: 2.35591369999997, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8785161, longitude: 2.35403099999996, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8750239, longitude: 2.34065428376198, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8754813, longitude: 2.32579569999996, tour: tour, passing_time: DateTime.now)
      TourPoint.create!(latitude: 48.8747899, longitude: 2.31991776565565, tour: tour, passing_time: DateTime.now)
    end

    private
    attr_reader :user
  end
end