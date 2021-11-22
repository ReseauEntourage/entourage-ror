module PoiServices
  class SoliguideShow
    def self.get id
      SoliguideFormatter.format JSON.parse(get_response(id).body)
    end

    private

    SHOW_URI = "https://api.soliguide.fr/place/%s"

    def self.api_key
      Soliguide::API_KEY
    end

    def self.get_response id
      uri = URI(SHOW_URI % id)

      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri, {
        'Content-Type' => 'application/json',
        'Authorization' => api_key,
      })

        http.request(request)
      end
    end
  end
end
