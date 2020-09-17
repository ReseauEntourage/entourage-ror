module PostgisHelper
  def self.point(latitude, longitude)
    latitude  = latitude.is_a?(Symbol)  ? latitude  : Float(latitude)
    longitude = longitude.is_a?(Symbol) ? longitude : Float(longitude)
    "ST_Transform(ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}),4326),3857)"
  end

  def self.distance_between(a, b)
    "ST_Distance(#{point(*a)}, #{point(*b)})"
  end

  def self.distance_from(latitude, longitude, table_name=nil)
    keys =
      if table_name != nil
        [:"#{table_name}.latitude", :"#{table_name}.longitude"]
      else
        [:latitude, :longitude]
      end
    distance_between([latitude, longitude], keys)
  end
end
