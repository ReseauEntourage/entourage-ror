module PoiServices
  class SoliguideIndex
    def self.post params
      JSON.parse(post_response(params).read_body)['places'].map do |poi|
        SoliguideFormatter.format_short poi
      end
    end

    private

    INDEX_URI = "https://api.soliguide.fr/new-search?%s"

    def self.headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => Soliguide::API_KEY,
      }
    end

    def self.post_response params
      uri = URI(INDEX_URI)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.post(uri.path, params.to_json, headers)
    end
  end
end
