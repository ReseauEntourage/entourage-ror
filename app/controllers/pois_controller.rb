class PoisController < ApplicationController

	def index
		@pois = Poi.all
	end

end
