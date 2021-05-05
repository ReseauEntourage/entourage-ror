class ToursEntourage < ApplicationRecord
  belongs_to :user

  reverse_geocoded_by :latitude, :longitude
end
