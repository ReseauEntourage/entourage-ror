class Encounter < ActiveRecord::Base

  validates :date, :street_person_name, :tour, presence: true
  validates :latitude, :longitude, presence: true, numericality: true

  belongs_to :tour

  reverse_geocoded_by :latitude, :longitude
  attr_encrypted :message, key: :crypting_key, if: :crypting_key_present?

  alias_attribute :voice_message, :voice_message_url

  def to_s
    "#{id} - Entre #{tour.user.full_name} et #{street_person_name}"
  end
  
  def crypting_key
    ENV['DB_CRYPTING_KEY']
  end
  
  def crypting_key_present?
    crypting_key.present?
  end

end