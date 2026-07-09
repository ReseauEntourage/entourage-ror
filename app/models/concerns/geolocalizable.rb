module Geolocalizable
  extend ActiveSupport::Concern

  included do
    scope :around, -> (latitude, longitude, distance) do
      box = geolocalizable_bounding_box(latitude, longitude, distance)
      return unless box

      within_bounding_box(box)
    end

    scope :clustered, -> (latitude, longitude, distance, filters = {}) {
      box = geolocalizable_bounding_box(latitude, longitude, distance)
      return unless box

      filters = filters.compact
      filters.each_key do |column|
        raise ArgumentError, "invalid clustered filter column: #{column}" unless column_names.include?(column.to_s)
      end

      pois_in_range = self.around(latitude, longitude, distance)
      pois_in_range = pois_in_range.where(filters) if filters.present?
      max_clusters = pois_in_range.count

      bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

      conditions_sql = [bounding_box_sql] + filters.map { |column, value|
        sanitize_sql_array(["#{column} = ?", value])
      }

      select("
        CASE WHEN COUNT(*) = 1 THEN MIN(pois.id) ELSE NULL END AS id,
        CASE WHEN COUNT(*) = 1 THEN MIN(pois.source) ELSE NULL END AS source,
        CASE WHEN COUNT(*) = 1 THEN MIN(pois.source_id) ELSE NULL END AS source_id,
        CASE WHEN COUNT(*) = 1 THEN MIN(pois.name) ELSE NULL END AS name,
        CASE WHEN COUNT(*) = 1 THEN MIN(pois.adress) ELSE NULL END AS adress,
        CASE WHEN COUNT(*) = 1 THEN MIN(pois.phone) ELSE NULL END AS phone,
        CASE WHEN COUNT(*) = 1 THEN MIN(pois.email) ELSE NULL END AS email,
        CASE WHEN COUNT(*) = 1 THEN MIN(pois.category_id) ELSE NULL END AS category_id,
        COUNT(*) AS count,
        AVG(pois.latitude) AS latitude,
        AVG(pois.longitude) AS longitude
      ").from(sanitize_sql_array ["(
        SELECT id, validated, source, source_id, name, adress, latitude, phone, email, longitude, category_id, ST_ClusterKMeans(ST_Transform((ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))::geometry, 4326), LEAST(#{max_clusters}, 30)) OVER () AS cluster_id
        FROM pois as to_be_clustered
        WHERE #{conditions_sql.join(' AND ')}
      ) AS pois"]).group('cluster_id')
    }

    def self.geolocalizable_bounding_box(latitude, longitude, distance)
      return unless latitude && longitude

      Geocoder::Calculations.bounding_box([latitude, longitude], distance || 10, units: :km)
    end
  end
end
