class Encounter < ActiveRecord::Base

  validates :date, :user_id, :street_person_name, presence: true
  validates :latitude, :longitude, presence: true, numericality: true

	belongs_to :user
  
  geocoded_by :address

  alias_attribute :voice_message, :voice_message_url

  def to_s
    "#{id} - Entre #{user.first_name} et #{street_person_name}"
  end
end