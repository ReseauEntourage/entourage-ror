class Poi < ActiveRecord::Base

  validates :name, presence: true
  validates :latitude, :longitude, numericality: true
  belongs_to :category
  
end
