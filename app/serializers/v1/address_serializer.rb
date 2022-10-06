module V1
  class AddressSerializer < ActiveModel::Serializer
    attributes :latitude,
               :longitude,
               :display_address,
               :position

    def initialize
      UserServices::AddressService.update_city_if_nil(object)
    end
  end
end
