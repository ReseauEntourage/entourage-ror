module PostgisHelper
  def self.point(latitude, longitude)
    "ST_Transform(ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}),4326),3857)"
  end

  def self.distance_between(a, b)
    "ST_Distance(#{point(*a)}, #{point(*b)})"
  end

  def self.distance_from(latitude, longitude)
    distance_between([latitude, longitude], [:latitude, :longitude])
  end
end
