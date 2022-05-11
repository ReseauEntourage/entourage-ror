module V1
  class NeighborhoodOutingSerializer < ActiveModel::Serializer
    attributes :id,
               :uuid,
               :title,
               :description,
               :share_url,
               :image_url,
               :event_url,
               :author,
               :location

    def uuid
      object.uuid_v2
    end

    def location
      {
        latitude: object.latitude,
        longitude: object.longitude
      }
    end

    def author
      {
        id: object.user.id,
        display_name: UserPresenter.new(user: object.user).display_name,
        avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
      }
    end
  end
end
