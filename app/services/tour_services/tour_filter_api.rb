module TourServices
  class TourFilterApi
    def initialize(user:, status:, type:, vehicle_type:, latitude:, longitude:, distance:, page:, per:)
      @user = user
      @status = status
      @type = type
      @vehicle_type = vehicle_type
      @latitude = latitude
      @longitude = longitude
      @distance = distance
      @page = page
      @per = per
    end

    def tours
      tours = Tour.includes(:tour_points).includes(:join_requests).includes(:user)
      tours = tours.where(status: status) if status
      tours = tours.where(tour_type: type) if type
      tours = tours.where(vehicle_type: Tour.vehicle_types[vehicle_type.to_sym]) if vehicle_type
      tours = filter_box(tours) if latitude && longitude
      tours = tours.where("updated_at > ?", 24.hours.ago)
      tours.order(updated_at: :desc).page(page).per(per)
    end

    private
    attr_reader :user, :status, :type, :vehicle_type, :latitude, :longitude, :distance, :page, :per

    def filter_box(tours)
      points = TourPoint.within_bounding_box(box).select(:tour_id).distinct
      tours.where(id: points)
    end

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          (distance || 10),
                                          units: :km)
    end
  end
end