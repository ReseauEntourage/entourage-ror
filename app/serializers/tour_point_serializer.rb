class TourPointSerializer < ActiveModel::Serializer
  attributes :latitude,
             :longitude,
             :passing_time

  def passing_time
    object.passing_time.strftime("%H:%M")
  end
end