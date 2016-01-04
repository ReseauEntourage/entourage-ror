class TourPointSerializer < ActiveModel::Serializer
  attributes :latitude,
             :longitude,
             :passing_time
end