module V1
  class NeighborhoodSerializer < ActiveModel::Serializer
    attributes :id,
      :name,
      :description,
      :welcome_message,
      :member,
      :members_count,
      :image_url,
      :interests,
      :ethics,
      :past_outings_count,
      :future_outings_count,
      :has_ongoing_outing,
      :address,
      :status_changed_at

    has_one :user, serializer: ::V1::Users::BasicSerializer
    has_many :members, serializer: ::V1::Users::BasicSerializer

    def member
      return false unless scope && scope[:user]

      object.members.include? scope[:user]
    end

    def image_url
      object.image_url_with_size :medium
    end

    def interests
      object.interest_names.sort
    end

    def has_ongoing_outing
      object.has_ongoing_outing?
    end

    def address
      {
        latitude: object.latitude,
        longitude: object.longitude,
        display_address: [object.place_name, object.postal_code].compact.uniq.join(', ')
      }
    end
  end
end
