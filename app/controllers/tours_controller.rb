class ToursController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tour
  before_action :set_tour_presenter
  before_action :check_authorisations

  def show
  end

  def map_center
    first_tour_point = @tour.tour_points.first
    render json: [first_tour_point.latitude, first_tour_point.longitude]
  end

  def map_data
    features = [{"type" => "Feature",
                "properties" => {
                    "tour_type" => @tour_presenter.tour_type
                },
                "geometry" => {
                    "type" => "LineString",
                    "coordinates" => @tour_presenter.tour_points.map { |coordinate| [coordinate[:long], coordinate[:lat]] }
                    }
                }]

    render json: {"type" => "FeatureCollection",
                  "features" => features}
  end

  private
  def set_tour
    @tour = Tour.find(params[:id])
  end

  def set_tour_presenter
    @tour_presenter = TourPresenter.new(tour: @tour)
  end

  def check_authorisations
    unless Authentication::UserTourAuthenticator.new(user: current_user, tour: @tour).allowed_to_see?
      flash[:error] = "Vous ne pouvez pas consulter la maraude d'un autre utilisateur"
      redirect_to root_path
    end
  end
end