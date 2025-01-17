module V1
  class AddressSerializer < ActiveModel::Serializer
    attributes :latitude,
               :longitude,
               :display_address,
               :position

    def latitude
      return unless me?

      object.latitude
    end

    def longitude
      return unless me?

      object.longitude
    end

    def display_address
      address = UserServices::AddressService.update_city_if_nil(object)

      return "#{address.city}, #{address.postal_code}" unless me?
      return address.display_address unless address.city && address.postal_code

      "#{address.city}, #{address.postal_code}"
    end

    def city
      address = UserServices::AddressService.update_city_if_nil(object)
      address.city
    end

    def me?
      scope[:user] && (object.user_id == scope[:user].id)
    end
  end
end
