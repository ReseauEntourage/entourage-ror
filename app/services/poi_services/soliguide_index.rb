module PoiServices
  class SoliguideIndex
    INDEX_URI = "https://api.soliguide.fr/new-search?%s"
    BATCH_LIMIT = 1000

    FIND_ONE_PARAMS = {
      latitude: PoiServices::Soliguide::PARIS[:latitude],
      longitude: PoiServices::Soliguide::PARIS[:longitude],
      distance: 1,
      limit: 1
    }

    FIND_ALL_PARAMS = {
      latitude: PoiServices::Soliguide::PARIS[:latitude],
      longitude: PoiServices::Soliguide::PARIS[:longitude],
      distance: PoiServices::Soliguide::DISTANCE_ALL_MAX,
      limit: BATCH_LIMIT
    }

    class << self
      def post params
        get_results(params).map do |poi|
          PoiServices::SoliguideFormatter.format_short poi
        end
      end

      def post_only_query params
        get_results(params)
      end

      def post_all_for_page page
        post(find_all_params_for_page(page))
      end

      def uptime
        find_one_query
      end

      def find_one_query
        query(find_one_params)
      end

      def find_all_query
        query(find_all_params)
      end

      private

      def headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => PoiServices::Soliguide::API_KEY,
        }
      end

      def get_results params
        return post_response(params) unless params[:categories].present?

        params[:categories].map do |categorie|
          params[:categorie] = categorie

          post_response(params)
        end.inject(&:+)
      end

      def find_one_params
        @find_one_params ||= PoiServices::Soliguide.new(FIND_ONE_PARAMS).query_params
      end

      def find_all_params
        @find_all_params ||= PoiServices::Soliguide.new(FIND_ALL_PARAMS).query_all_params
      end

      def find_all_params_for_page page
        PoiServices::Soliguide.new(FIND_ALL_PARAMS.merge({ page: page })).query_all_params
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
