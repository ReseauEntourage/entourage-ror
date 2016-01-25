module V0
  class TourPointSerializer < ActiveModel::Serializer
    attributes :latitude,
               :longitude
  end
end