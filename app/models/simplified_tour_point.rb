class SimplifiedTourPoint < ApplicationRecord
  belongs_to :tour
  geocoded_by :address

  validates :longitude, :latitude, numericality: true, presence: true
  validates :tour_id, presence: true

  scope :ordered, -> { order("created_at ASC") }

  def passing_time
    created_at
  end
end
