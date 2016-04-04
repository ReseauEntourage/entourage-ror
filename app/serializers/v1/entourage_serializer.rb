module V1
  class EntourageSerializer < ActiveModel::Serializer
    attributes :id, :status, :title, :entourage_type, :number_of_people
    has_one :author
    has_one :location

    def author
      {
          id: object.user.id,
          name: object.user.first_name
      }
    end

    def location
      {
          latitude: object.longitude,
          longitude: object.longitude
      }
    end
  end
end
