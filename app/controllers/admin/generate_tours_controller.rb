module Admin
  class GenerateToursController < Admin::BaseController
    def index
    end

    def create
      return render json: {error: "missing_coordinates"}, status: 400 if params[:coordinates].blank?

      tour = current_admin.tours.create(closed_at: Time.now,
                                        status: :closed,
                                        vehicle_type: :feet,
                                        tour_type: :medical,
                                        length: 2200)

      params["coordinates"].each do |coordinate|
        tour.simplified_tour_points.create(longitude: coordinate["lng"],
                                             latitude: coordinate["lat"])
        tour.tour_points.create(longitude: coordinate["lng"],
                                 latitude: coordinate["lat"],
                                passing_time: Time.now)
      end

      render json: {status: :ok}
    end
  end
end