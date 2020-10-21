module PoiServices
  class PoiOptimizedSerializer
    CACHE_KEY_PREFIX = "json_cache/#{Poi.model_name.cache_key}".freeze
    CACHE_KEY_FORMAT = "#{CACHE_KEY_PREFIX}/%s/%s-%s".freeze

    def initialize(pois_scope, box_size:, version:, &serializer)
      @pois = pois_scope
      @box_size = box_size.to_f
      @version = version
      @serializer = serializer
    end

    def serialize
      pois_metadata = metadata_with_clustering(@pois)

      return [] if pois_metadata.empty?

      cache_keys_by_id = {}
      pois_metadata.each do |id, timestamp|
        cache_keys_by_id[id.to_i] = CACHE_KEY_FORMAT % [@version, id, timestamp]
      end

      cached_values = $redis.mget(*cache_keys_by_id.values)

      ids = cache_keys_by_id.keys
      pois_by_id = {}
      ids_to_fetch_from_database = []

      ids.zip(cached_values).each do |id, cached_value|
        if cached_value != nil
          pois_by_id[id] = cached_value
        else
          ids_to_fetch_from_database.push(id)
        end
      end

      if ids_to_fetch_from_database.any?
        pois_from_database = Poi.where(id: ids_to_fetch_from_database)
        cache_writes = []

        @serializer.call(pois_from_database).each_with_index do |serialized_poi, i|
          json = serialized_poi.to_json

          # This assumes that the serializer respects the order of the pois
          # which is true for ActiveModel::ArraySerializer
          poi_id = pois_from_database[i].id

          pois_by_id[poi_id] = json
          cache_writes.push(cache_keys_by_id[poi_id], json)
        end

        $redis.mset(*cache_writes)
      end

      ids.map { |id| SerializedJSON.new(pois_by_id[id]) }
    end

    private
    # Divides the area in a grid of squares and keep only one POI per square
    def metadata_with_clustering scope
      if @box_size >= 10
        grid_size = @box_size / 15
      elsif @box_size >= 5
        grid_size = @box_size / 30
      else
        # no clustering
        grid_size = nil
      end

      scope = scope.unscope(:select)
      projections = [
        "pois.id",
        "to_char(pois.updated_at, 'YYYYMMDDHH24MISSUS000')"
      ]

      if grid_size
        # The sorting expression of the `distinct on` clause conflicts
        # with the one we want to use to sort the results globally.
        # To solve this, we cluster in a CTE, then sort again in the main query.

        cte_projections = [
          "pois.id", "pois.updated_at",     # for the metadata
          "pois.latitude", "pois.longitude" # for the sorting by distance
        ]

        # prefix a `distinct on` clause to the first expression for clustering
        cte_projections[0] = %{
          distinct on (
            ST_SnapToGrid(
              #{PostgisHelper.point(:"pois.latitude", :"pois.longitude")},
              #{grid_size * 1000})
          )
          #{cte_projections[0]}
        }

        sql = %(
          with pois as (
            #{scope.unscope(:order, :limit).select(*cte_projections).to_sql}
          )
          #{scope.unscope(:where, :joins).select(*projections).to_sql}
        ).squish
      else
        sql = scope.select(*projections).to_sql
      end

      result = ActiveRecord::Base.connection.execute(sql)
      metadata = result.values
      result.clear

      metadata
    end

    # wraps a JSON fragment to prevent the encoder to re-serialize it
    class SerializedJSON < BasicObject
      def initialize(json)
        @json = json
      end

      def as_json *args
        self
      end

      def to_json *args
        @json
      end
    end

    # patches the JSON encoder to handle pre-serialized fragments
    module EncoderMixin
      private
      def jsonify(value)
        case value
        when SerializedJSON
          value
        else
          super
        end
      end
    end

    ActiveSupport.json_encoder.prepend(EncoderMixin)

    def self.clear_cache
      $redis.del($redis.keys("#{CACHE_KEY_PREFIX}/*"))
    end
  end
end
