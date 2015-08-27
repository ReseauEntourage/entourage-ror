class MapController < ApplicationController

  def index
  	pois_limit = params[:limit].nil? ? 45 : params[:limit]
    @categories = Category.all
    if(params.has_key?(:longitude) && params.has_key?(:latitude) && params.has_key?(:distance))
      @pois = Poi.around(params[:latitude], params[:longitude], params[:distance]).limit(pois_limit)
    else
      @pois = Poi.all.order(:id).limit(pois_limit)
    end
    @encounters = Encounter.all.includes(tour: [:user])
  end

end
