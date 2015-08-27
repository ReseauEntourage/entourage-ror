class PoisController < ApplicationController
  
  def index
    @categories = Category.all
    @pois = Poi.all
    @pois = @pois.around params[:latitude], params[:longitude], params[:distance] if params[:latitude].present? and params[:longitude].present?
  end

end
