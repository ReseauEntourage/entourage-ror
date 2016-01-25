module V0
  class TourPointSerializer < ActiveModel::Serializer
    attributes :latitude,
               :longitude,
               :passing_time
  end
end