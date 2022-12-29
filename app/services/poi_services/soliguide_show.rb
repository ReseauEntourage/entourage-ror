module PoiServices
  class SoliguideShow
    SHOW_URI = "https://api.soliguide.fr/place/%s"
    UPTIME_DEFAULT = 0

    class << self
      def get id
        PoiServices::SoliguideFormatter.format JSON.parse(query(id).body)
      end

      def uptime
        query UPTIME_DEFAULT
      end

      private

      def headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => PoiServices::Soliguide::API_KEY,
        }
      end

      def query id
        uri = URI(SHOW_URI % id)

        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request Net::HTTP::Get.new(uri, headers)
        end
      end
    end
  end
end
