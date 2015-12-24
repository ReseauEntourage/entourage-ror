class ToursController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tour

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
end