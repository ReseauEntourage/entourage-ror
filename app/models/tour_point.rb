class TourPoint < ActiveRecord::Base
  
  validates_numericality_of :latitude, :longitude
  belongs_to :tour

end
