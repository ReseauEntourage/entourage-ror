class Poi < ActiveRecord::Base

  validates_presence_of :name, :category
  validates :latitude, :longitude, numericality: true
  validates :partner_id, presence: true, allow_nil: true
  belongs_to :category
  has_and_belongs_to_many :categories

  geocoded_by :adress

  scope :validated, -> { where(validated: true) }

  scope :around, -> (latitude, longitude, distance) do
    distance ||= 10
    box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    within_bounding_box(box)
  end

end
