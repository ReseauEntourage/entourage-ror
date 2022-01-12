module PoiServices
  class SoliguideIndex
    def self.post params
      get_results(params).map do |poi|
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

    def self.get_results params
      return post_response(params) unless params[:categories].present?

      params[:categories].map do |categorie|
        params[:categorie] = categorie

        post_response(params)
      end.inject(&:+)
    end

    def self.post_response params
      uri = URI(INDEX_URI)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      JSON.parse(http.post(uri.path, params.to_json, headers).read_body)['places'] || []
    rescue JSON::ParserError => e
      []
    end
  end
end
