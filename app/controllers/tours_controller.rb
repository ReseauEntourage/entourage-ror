class ToursController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def create
    @tour = Tour.new(tour_params)
    if @tour.save
      render "show", status: 201
    else
      render '400', status: 400
    end
  end

  def show
    if @tour = Tour.find_by(id: params[:id])
      render status: 200
    else
      @id = params[:id]
      render '404', status: 404
    end
  end

  def index
    @tours = Tour.order(updated_at: :desc).take(params.fetch(:limit, 10))
    render status: 200
  end

  def update
    if @tour = Tour.find_by(id: params[:id])
      @tour.update_attributes(tour_params)
      render 'show', status: 200
    else
      @id = params[:id]
      render '404', status: 404
    end
  end

private

  def tour_params
    params.require(:tour).permit(:tour_type, :status)
  end

end
