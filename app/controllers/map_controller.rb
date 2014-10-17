class MapController < ApplicationController

  def index
    @categories = Category.all
    @pois = Poi.all.limit(10)
    @encounters = Encounter.all.includes(:user)
  end

end
