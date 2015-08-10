class ToursController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def create
    @tour = Tour.new(tour_params)
    @tour.user = @current_user
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
    @tours = Tour.where(nil)
    @tours = @tours.type(params[:type]) if params[:type].present?
    @tours = @tours.vehicle_type(Tour.vehicle_types[params[:vehicle_type]]) if params[:vehicle_type].present?
    
    if (params[:latitude].present? && params[:longitude].present?)
      center_point = [params[:latitude], params[:longitude]]
      distance = params.fetch(:distance, 10)
      box = Geocoder::Calculations.bounding_box(center_point, distance, :units => :km)
      points = TourPoint.unscoped.within_bounding_box(box).select(:tour_id).distinct
      @tours = @tours.where(id: points)
    end
    
    @tours = @tours.order(updated_at: :desc).take(params.fetch(:limit, 10))
    render status: 200
  end

  def update
    if @tour = Tour.find_by(id: params[:id])
      if @tour.user != @current_user
        head 403
      else
        @tour.update_attributes(tour_params)
        render 'show', status: 200
      end
    else
      @id = params[:id]
      render '404', status: 404
    end
  end

private

  def tour_params
    params.require(:tour).permit(:tour_type, :status, :vehicle_type)
  end

end
