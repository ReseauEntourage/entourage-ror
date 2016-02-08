module TourServices
  class FakeTour
    def initialize(user:)
      @user = user
    end

    def create_tour!(status:)
      params = {tour_type: "medical",
                vehicle_type: "feet",
                status: status}
      TourServices::TourBuilder.new(params: params, user: user).create
    end

    private
    attr_reader :user
  end
end