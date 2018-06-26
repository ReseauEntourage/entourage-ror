class Address < ActiveRecord::Base
  validates_presence_of :name, :latitude, :longitude
end
