class TourPoint < ActiveRecord::Base

  validates_numericality_of :latitude, :longitude
  belongs_to :tour
  default_scope { order('passing_time') }
  
  geocoded_by :address

  scope :around, -> (latitude, longitude, distance) do
    distance ||= 10
    box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    within_bounding_box(box)
  end

end
