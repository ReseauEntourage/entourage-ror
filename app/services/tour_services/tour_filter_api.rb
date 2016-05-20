module TourServices
  class TourFilterApi
    def initialize(user:, status:, type:, vehicle_type:, latitude:, longitude:, distance:, time_range: 24, page:, per:)
      @user = user
      @status = status
      @type = type
      @vehicle_type = vehicle_type
      @latitude = latitude
      @longitude = longitude
      @distance = distance
      @time_range = time_range.to_i
      @page = page
      @per = per
    end

    def tours
      tours = Tour.includes(:tour_points, :join_requests, :user)
      tours = tours.where(status: status) if status
      tours = tours.where(tour_type: formated_types) if type
      tours = tours.where(vehicle_type: Tour.vehicle_types[vehicle_type.to_sym]) if vehicle_type
      tours = filter_box(tours) if latitude && longitude
      tours = tours.where("tours.created_at > ?", time_range.hours.ago)
      tours.order(updated_at: :desc).page(page).per(per)
    end

    private
    attr_reader :user, :status, :type, :vehicle_type, :latitude, :longitude, :distance, :time_range, :page, :per

    def filter_box(tours)
      points = TourPoint.within_bounding_box(box).select(:tour_id).distinct
      tours.where(id: points)
    end

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          (distance || 10),
                                          units: :km)
    end

    def formated_types
      type.gsub(" ", "").split(",")
    end
  end
end