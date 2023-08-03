module V1
  class NeighborhoodSerializer < ActiveModel::Serializer
    attributes :id,
      :uuid_v2,
      :name,
      :description,
      :welcome_message,
      :member,
      :members,
      :members_count,
      :image_url,
      :interests,
      :ethics,
      :future_outings_count,
      :address,
      :status_changed_at,
      :public

    has_one :user, serializer: ::V1::Users::BasicSerializer

    def member
      return false unless scope && scope[:user]

      object.members.include? scope[:user]
    end

    def members
      # we assume this serializer is only used in case where members is not used
      # to assure retrocompatibility with former app versions, we need this method to be compatible with "members.size"
      # so we want this method to return an array of "members" elements
      Array.new(object.members_count, 1)
    end

    def image_url
      object.image_url_with_size :medium
    end

    def interests
      object.interest_names.sort
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
