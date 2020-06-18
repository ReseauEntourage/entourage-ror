module V1
  class AddressSerializer < ActiveModel::Serializer
    attributes :latitude,
               :longitude,
               :display_address,
               :position
  end
end
