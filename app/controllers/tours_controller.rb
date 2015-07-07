class ToursController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def create
    @tour = Tour.new(tour_params)
    if @tour.save
      render status: 201
    else
      render 'error', status: 400
    end
  end

  def tour_params
    params.require(:tour).permit(:tour_type)
  end

end
