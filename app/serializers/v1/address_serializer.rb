module V1
  class AddressSerializer < ActiveModel::Serializer
    attributes :latitude,
               :longitude,
               :display_address,
               :position

    def display_address
      address = UserServices::AddressService.update_city_if_nil(object)

      return address.display_address unless address.city && address.postal_code

      "%s, %s" % [address.city, address.postal_code]
    end
  end
end
