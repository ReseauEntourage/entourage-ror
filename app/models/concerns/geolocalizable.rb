module Geolocalizable
  extend ActiveSupport::Concern

  included do
    scope :around, -> (latitude, longitude, distance) do
      distance ||= 10
      box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
      within_bounding_box(box)
    end

    scope :clustered, -> (latitude, longitude, distance) {
      max_clusters = self.around(latitude, longitude, distance).count
      box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
      bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

      select("
        CASE WHEN COUNT(*) = 1 THEN MIN(id) ELSE NULL END AS id,
        CASE WHEN COUNT(*) = 1 THEN MIN(name) ELSE NULL END AS name,
        COUNT(*) AS count,
        AVG(latitude) AS avg_latitude,
        AVG(longitude) AS avg_longitude
      ").from(sanitize_sql_array ["(
        SELECT id, name, latitude, longitude, ST_ClusterKMeans(ST_Transform((ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))::geometry, 4326), LEAST(#{max_clusters}, 30)) OVER () AS cluster_id
        FROM pois
        WHERE #{bounding_box_sql}
      ) AS clusters"]).group("cluster_id")
    }
  end
end
