module PoiServices
  class SoliguideImporter
    attr_reader :starting_time
    attr_reader :poi_attributes
    attr_reader :batch_limit

    def initialize
      @starting_time = Time.zone.now
      @poi_attributes = Poi.attribute_names.map(&:to_sym)
      @batch_limit = PoiServices::SoliguideIndex::BATCH_LIMIT
    end

    def create_all
      find_all_iterator do |page|
        post_all_for_page(page).each do |response|
          poi = Poi.find_or_initialize_by(source_id: response[:source_id])
          poi.update_attributes(response.slice(*poi_attributes))
          poi.source = :soliguide
          poi.validated = true
          poi.updated_at = Time.zone.now
          poi.save!
        end
      end

      remove_deprecated_pois
    end

    private

    def remove_deprecated_pois
      Rails.logger.info("#{self.class.name} unvalidate POI older than #{starting_time}")

      Poi.source_soliguide.where('updated_at < ?', starting_time).update_all(validated: false)
    end

    def find_all_iterator
      Rails.logger.info("#{self.class.name} fetching #{nb_results} results")

      0.step(nb_results - 1, batch_limit) do |results|
        yield (results / batch_limit) + 1
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
      Rails.logger.error("type=soliguide_importer error: class=#{e.class} message=#{e.message.inspect}")

      1
    end
  end
end
