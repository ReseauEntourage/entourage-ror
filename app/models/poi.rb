class Poi < ActiveRecord::Base

  validates :name, presence: true
  validates :latitude, :longitude, numericality: true
  belongs_to :category
  
  geocoded_by :address
  
  default_scope { where(validated: true) }
  
  scope :around, -> (latitude, longitude, distance) do
    distance ||= 10
    box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    within_bounding_box(box)
  end

end
