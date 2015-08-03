class TourPoint < ActiveRecord::Base
  
  validates_numericality_of :latitude, :longitude
  belongs_to :tour
  default_scope { order('passing_time') }
  
  geocoded_by :address
  
end
