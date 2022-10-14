module PoiServices
  class SoliguideIndex
    INDEX_URI = "https://api.soliguide.fr/new-search?%s"

    class << self
      def post params
        get_results(params).map do |poi|
          PoiServices::SoliguideFormatter.format_short poi
        end
      end

      def uptime
        query(default_params)
      end

      private

      def headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => Soliguide::API_KEY,
        }
      end

      def get_results params
        return post_response(params) unless params[:categories].present?

        params[:categories].map do |categorie|
          params[:categorie] = categorie

          post_response(params)
        end.inject(&:+)
      end

      def default_params
        PoiServices::Soliguide.new({
          latitude: PoiServices::Soliguide::PARIS[:latitude],
          longitude: PoiServices::Soliguide::PARIS[:longitude],
          distance: 1,
          limit: 1
        }).query_params
      end

      def post_response params
        JSON.parse(query(params).read_body)['places'] || []
      rescue JSON::ParserError => e
        []
      end

      def query params
        uri = URI(INDEX_URI)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        http.post(uri.path, params.to_json, headers)
      end
    end
  end
end
