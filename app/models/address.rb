class Address < ActiveRecord::Base
  validates_presence_of :place_name, :latitude, :longitude
end
