class SimplifiedTourPoint < ActiveRecord::Base
  belongs_to :tour
  geocoded_by :address

  validates :longitude, :latitude, numericality: true, presence: true
  validates :tour_id, presence: true
end