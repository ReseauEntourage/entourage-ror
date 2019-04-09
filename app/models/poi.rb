class Poi < ActiveRecord::Base

  validates_presence_of :name, :category
  validates :latitude, :longitude, numericality: true
  belongs_to :category

  geocoded_by :adress

  scope :validated, -> { where(validated: true) }

  scope :around, -> (latitude, longitude, distance) do
    distance ||= 10
    box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    within_bounding_box(box)
  end

end
