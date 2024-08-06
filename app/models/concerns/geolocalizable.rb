module Geolocalizable
  extend ActiveSupport::Concern

  included do
    scope :around, -> (latitude, longitude, distance) do
      return unless latitude && longitude

      distance ||= 10
      box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
      within_bounding_box(box)
    end

    scope :clustered, -> (latitude, longitude, distance) {
      return unless latitude && longitude

      max_clusters = self.around(latitude, longitude, distance).count
      box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
      bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

      select("
        CASE WHEN COUNT(*) = 1 THEN MIN(id) ELSE NULL END AS id,
        CASE WHEN COUNT(*) = 1 THEN MIN(source) ELSE NULL END AS source,
        CASE WHEN COUNT(*) = 1 THEN MIN(source_id) ELSE NULL END AS source_id,
        CASE WHEN COUNT(*) = 1 THEN MIN(name) ELSE NULL END AS name,
        CASE WHEN COUNT(*) = 1 THEN MIN(adress) ELSE NULL END AS adress,
        CASE WHEN COUNT(*) = 1 THEN MIN(phone) ELSE NULL END AS phone,
        CASE WHEN COUNT(*) = 1 THEN MIN(email) ELSE NULL END AS email,
        CASE WHEN COUNT(*) = 1 THEN MIN(category_id) ELSE NULL END AS category_id,
        COUNT(*) AS count,
        AVG(latitude) AS latitude,
        AVG(longitude) AS longitude
      ").from(sanitize_sql_array ["(
        SELECT id, source, source_id, name, adress, latitude, phone, email, longitude, category_id, ST_ClusterKMeans(ST_Transform((ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))::geometry, 4326), LEAST(#{max_clusters}, 30)) OVER () AS cluster_id
        FROM pois
        WHERE #{bounding_box_sql}
      ) AS clusters"]).group("cluster_id")
    }
  end
end
