class MapController < ApplicationController

  def index
    @categories = Category.all
    @pois = Poi.all
    @encounters = Encounter.all.includes(:user)
  end

end
