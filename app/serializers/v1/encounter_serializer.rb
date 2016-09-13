module V1
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

    def street_person_name
      object.street_person_name || "xxxx"
    end

    def message
      begin
        object.message
      rescue OpenSSL::Cipher::CipherError => e
        Rails.logger.error "Cound not decrypt message for Encounter #{object.id}"
        "Unreadable message"
      end
    end
  end
end
