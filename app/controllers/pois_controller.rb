class PoisController < ApplicationController
  
	def index
		@categories = Category.all
		@pois = Poi.all
	end

end
