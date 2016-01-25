module V1
  class TourPointSerializer < ActiveModel::Serializer
    attributes :latitude,
               :longitude
  end
end