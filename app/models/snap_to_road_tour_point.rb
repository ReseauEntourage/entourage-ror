class SnapToRoadTourPoint < ActiveRecord::Base
  belongs_to :tour

  validates :longitude, :latitude, numericality: true, presence: true
  validates :tour_id, presence: true
end