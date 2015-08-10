class Encounter < ActiveRecord::Base

  validates :date, :street_person_name, :tour, presence: true
  validates :latitude, :longitude, presence: true, numericality: true

  belongs_to :tour

  geocoded_by :address

  alias_attribute :voice_message, :voice_message_url

  def to_s
    "#{id} - Entre #{user.first_name} et #{street_person_name}"
  end
end