require "geocoder/lookups/google"

module Geocoder
  module Lookup
    class GoogleFindPlaceSearch < Google
      def name
        "Google Find Place Search"
      end

      def required_api_key_parts
        ["key"]
      end

      def supported_protocols
        [:https]
      end

      private


      def query_url(query)
        "#{protocol}://maps.googleapis.com/maps/api/place/findplacefromtext/json?" + url_query_string(query)
      end

      def results(query)
        return [] unless doc = fetch_data(query)

        case doc["status"]
        when "OK"
          return doc["candidates"]
        when "OVER_QUERY_LIMIT"
          raise_error(Geocoder::OverQueryLimitError) || Geocoder.log(:warn, "#{name} API error: over query limit.")
        when "REQUEST_DENIED"
          raise_error(Geocoder::RequestDenied) || Geocoder.log(:warn, "#{name} API error: request denied.")
        when "INVALID_REQUEST"
          raise_error(Geocoder::InvalidRequest) || Geocoder.log(:warn, "#{name} API error: invalid request.")
        end

        []
      end

      def query_url_google_params(query)
        {
          input: query.text,
          inputtype: :textquery,
          language: query.language || configuration.language
        }
      end

      def result_class
        Geocoder::Result::GooglePlacesDetails
      end
    end
  end
end

unless Geocoder::Lookup.street_services.include? :google_find_place_search
  Geocoder::Lookup.street_services.push :google_find_place_search
end
