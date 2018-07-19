class Address < ActiveRecord::Base
  validates_presence_of :place_name, :latitude, :longitude

  has_one :user

  def display_address
    [place_name, postal_code].compact.uniq.join(', ')
  end
end
