module PoiServices
  class SoliguideShow
    def self.get id
      SoliguideFormatter.format JSON.parse(get_response(id).body)
    end

    private

    SHOW_URI = "https://api.soliguide.fr/place/%s"

    def self.headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => Soliguide::API_KEY,
      }
    end

    def self.get_response id
      uri = URI(SHOW_URI % id)

      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request Net::HTTP::Get.new(uri, headers)
      end
    end
  end
end
