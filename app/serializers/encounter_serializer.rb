class EncounterSerializer < ActiveModel::Serializer
  attributes :id,
             :date,
             :latitude,
             :longitude,
             :user_id,
             :user_name,
             :street_person_name,
             :message,
             :voice_message

  def user_id
    object.tour.user.id
  end

  def user_name
    object.tour.user.first_name
  end

  def voice_message
    object.voice_message_url
  end
end