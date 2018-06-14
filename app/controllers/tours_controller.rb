class ToursController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tour
  before_action :set_tour_presenter
  before_action :check_authorisations, except: [:destroy]
  before_action :check_destroy_authorisations, only: [:destroy]

  def show
    flash[:alert] = "Cette maraude n'a aucun point" if @tour.empty_points?
  end

  def map_center
    return render json: [] if @tour.empty_points?

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
                    "coordinates" => @tour_presenter.simplified_tour_points.map { |coordinate| [coordinate[:long], coordinate[:lat]] }
                    }
                }]

    render json: {"type" => "FeatureCollection",
                  "features" => features}
  end

  def destroy
    if @tour.destroy
      flash[:success] = "La maraude a été supprimée"
      redirect_to dashboard_organizations_path
    else
      flash[:error] = "Une erreur technique a empêché la suppression de cette maraude."
      redirect_to @tour
    end
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

  def check_destroy_authorisations
    unless Authentication::UserTourAuthenticator.new(user: current_user, tour: @tour).allowed_to_destroy?
      flash[:error] = "Vous ne pouvez pas supprimer la maraude d'un autre utilisateur"
      redirect_to root_path
    end
  end
end
