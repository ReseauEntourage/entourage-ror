class Poi < ActiveRecord::Base

  validates :name, presence: true
  validates :latitude, :longitude, numericality: true
  belongs_to :category
  
  geocoded_by :address

  def self.find_pois_in_square(latitude, longitude, radius)
    distance = radius
    center_point = [latitude, longitude]
    box = Geocoder::Calculations.bounding_box(center_point, distance, :units => :km)
    Poi.within_bounding_box(box).order(:id)
  end

end
