class GoogleMap::TourSerializer < ActiveModel::Serializer
  attributes :type,
             :properties,
             :geometry

  def type
    "FeatureCollection"
  end

  def properties
    { tour_type: object.tour_type }
  end

  def geometry
    {
      type: "LineString",
      coordinates: coordinates
    }
  end

  def coordinates
    object.tour_points.map do |point|
      [point.longitude, point.latitude]
    end
  end
end