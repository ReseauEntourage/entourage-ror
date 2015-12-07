module Admin
  class GenerateTourController < Admin::BaseController

    def generate
      return render json: {error: "missing_coordinates"}, status: 400 if params[:coordinates].blank?

      tour = current_admin.tours.create(closed_at: Time.now,
                                        email_sent: true,
                                        status: :closed,
                                        vehicle_type: :feet,
                                        tour_type: :social)

      params["coordinates"].each do |coordinate|
        tour.snap_to_road_tour_points.create(longitude: coordinate["lng"],
                                             latitude: coordinate["lat"])
      end

      render json: {status: :ok}
    end
  end
end