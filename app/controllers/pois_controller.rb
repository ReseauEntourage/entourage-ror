class PoisController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  
  def index
    @categories = Category.all
    @pois = Poi.all
    @pois = @pois.around params[:latitude], params[:longitude], params[:distance] if params[:latitude].present? and params[:longitude].present?
  end
  
  def create
    @poi = Poi.new(poi_params)
    @poi.validated = false
    if @poi.save
      render "show", status: 201
    else
      render '400', status: 400
    end
  end
  
  private
  
  def poi_params
    params.require(:poi).permit(:name, :latitude, :longitude, :adress, :phone, :website, :email, :audience, :category_id)
  end

end
