class TourPoint < ActiveRecord::Base

  validates_numericality_of :latitude, :longitude
  belongs_to :tour

  geocoded_by :address

  scope :ordered, -> { order("passing_time DESC") }

  scope :around, -> (latitude, longitude, distance) do
    distance ||= 10
    box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    within_bounding_box(box)
  end

end
