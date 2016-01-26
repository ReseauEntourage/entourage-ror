class Entourage < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :status, :title, :entourage_type, :user_id, :latitude, :longitude, :number_of_people
end
