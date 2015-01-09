class MapController < ApplicationController

  def index
  	pois_limit = params[:limit].nil? ? 45 : params[:limit]
    @categories = Category.all
    @pois = Poi.all.order(:id).limit(pois_limit)
    @encounters = Encounter.all.includes(:user)
  end

end
