module Experimental
  # - symbolizes keys for the user-facing representation
  # - casts 'date-time-iso8601' between ActiveSupport::TimeWithZone
  #   and the appropriate representation for SQL comparisons
  #
  # the Hash/JSON needs to have a $id property
  # the $id property must have the format "urn:#{schema_repo}(:...)"
  # `schema_repo` is the `underscore`d name of a class
  # that has a `json_schema` method that returns a schema given an URN
  #
  # e.g.
  #    class Entourage < ActiveRecord::Base
  #      def self.json_schema urn
  #        case urn
  #        when 'metadata'
  #          {
  #            properties: {
  #              starts_at: { format: 'date-time-iso8601' }
  #            }
  #          }
  #        end
  #      end
  #
  #      attribute :metadata, :jsonb_with_schema
  #    end
  #
  #  enables this behavior for the `metadata` jsonb attribute:
  #  accepts writes with string keys, ISO8601 datetimes:
  #    entourage.metadata =   {"starts_at"=>"2018-07-07T19:42:47+02:00",
  #                            "$id"=>"urn:entourage:outing:metadata"}
  #
  #  serializes the date in a format appropriate for SQL comparisons:
  #    JSON in database:      {"starts_at": "2018-07-07 17:42:42.000000",
  #                            "$id": "urn:entourage:outing:metadata"}
  #
  #  allows these kinds of queries:
  #    Entourage.where("metadata->>'starts_at' = ?", date)
  #    Entourage.where("metadata->>'starts_at' between ? and ?", from, to)
  #
  #  symbolizes keys and casts date to ActiveSupport::TimeWithZone on read:
  #    p entourage.metadata # {:starts_at => Sat, 07 Jul 2018 19:44:51 CEST +02:00,
  #                            :$id =>"urn:entourage:outing:metadata"}
  #
  class JsonbWithSchema < ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb
    def deserialize(value)
      value = super(value)
      value = value.symbolize_keys
      cast_datetime_properties(value) do |datetime|
        converted = timezone_converter.deserialize(datetime)
        # keep invalid user-supplied values for clearer validation errors
        if converted.nil? && !datetime.nil?
          datetime
        else
          converted
        end
      end
    end

    def cast(value)
      value = value.symbolize_keys
      value = cast_datetime_properties(value) do |datetime|
        converted = timezone_converter.cast(datetime)
        # keep invalid user-supplied values for clearer validation errors
        if converted.nil? && !datetime.nil?
          datetime
        else
          converted
        end
      end
      super(value)
    end

    def serialize(value)
      value = value.symbolize_keys
      value = cast_datetime_properties(value) do |datetime|
        next if datetime.nil?
        # re-casts in case the shema was absent/different on assignment
        converted = timezone_converter.cast(datetime)
        # keep invalid user-supplied values for clearer validation errors
        if converted.nil?
          datetime
        else
          connection_adapter.quoted_date(converted)
        end
      end
      super(value)
    end

    private

    def cast_datetime_properties(value)
      datetime_properties(value).each do |property|
        next unless value.key?(property)
        value[property] = yield value[property]
      end
      value
    end

    def datetime_properties(value)
      urn = value[:$id]
      return [] if urn.nil?

      @datetime_properties ||= {}
      @datetime_properties[urn] ||= begin
        urn_fragments = urn.to_s.split(':')
        class_name = urn_fragments[1].camelize
        schema_urn_suffix = urn_fragments[2..-1].join(':')
        schema = class_name.safe_constantize.json_schema(schema_urn_suffix)
        schema.symbolize_keys.fetch(:properties, []).find_all do |_, property|
          property.symbolize_keys[:format] == 'date-time-iso8601'
        end.map(&:first)
      end
    end

    def connection_adapter
      ActiveRecord::Base.connection
    end

    def timezone_converter
      @timezone_converter ||=
        ActiveRecord::AttributeMethods::TimeZoneConversion::TimeZoneConverter.new(
          connection_adapter.type_map.fetch(
            connection_adapter.type_to_sql(:datetime)
          )
        )
    end
  end
end
