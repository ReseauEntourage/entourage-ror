module Admin
  class GenerateTourController < Admin::BaseController

    def generate
      return render json: {error: "missing_coordinates"}, status: 400 if params[:coordinates].blank?

      tour = current_admin.tours.create(closed_at: Time.now,
                                        status: :closed,
                                        vehicle_type: :feet,
                                        tour_type: :social,
                                        length: 2200)

      params["coordinates"].each do |coordinate|
        tour.snap_to_road_tour_points.create(longitude: coordinate["lng"],
                                             latitude: coordinate["lat"])
        tour.tour_points.create(longitude: coordinate["lng"],
                                 latitude: coordinate["lat"],
                                passing_time: Time.now)
      end

      render json: {status: :ok}
    end
  end
end