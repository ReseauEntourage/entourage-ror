module PoiServices
  class SoliguideImporter
    attr_reader :starting_time
    attr_reader :accepted_keys
    attr_reader :batch_limit

    def initialize
      @starting_time = Time.zone.now

      @accepted_keys = Poi.attribute_names.map(&:to_sym)
      @batch_limit = PoiServices::SoliguideIndex::BATCH_LIMIT
    end

    def create_all
      find_all_iterator do |page|
        post_all_for_page(page).each do |response|
          Poi.new(response.slice(*accepted_keys)).save!
        end
      end

      remove_deprecated_pois
    end

    private

    def remove_deprecated_pois
      Poi.source_soliguide.where('updated_at < ?', starting_time).delete_all
    end

    def find_all_iterator
      1.step(nb_results, batch_limit) do |results|
        yield results / batch_limit
      end
    end

    def find_all_query
      @find_all_query ||= PoiServices::SoliguideIndex.find_all_query
    end

    def post_all_for_page page
      PoiServices::SoliguideIndex.post_all_for_page(page)
    end

    def nb_results
      @nb_results ||= JSON.parse(find_all_query.read_body)['nbResults']
    rescue => e
      1
    end
  end
end
