class ToursController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tour
  before_action :set_tour_presenter

  def show
    unless Authentication::UserTourAuthenticator.new(user: current_user, tour: @tour).allowed_to_see?
      flash[:error] = "Vous ne pouvez pas consulter la maraude d'un autre utilisateur"
      redirect_to root_path
    end
  end

  private
  def set_tour
    @tour = Tour.find(params[:id])
  end

  def set_tour_presenter
    @tour_presenter = TourPresenter.new(tour: @tour)
  end
end