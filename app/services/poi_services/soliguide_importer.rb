module PoiServices
  class SoliguideImporter
    # "S'orienter": catch-all category for Soliguide services with no (or no recognized) category
    DEFAULT_CATEGORY_ID = 5

    attr_reader :starting_time
    attr_reader :poi_attributes
    attr_reader :batch_limit

    def initialize
      @starting_time = Time.zone.now
      @poi_attributes = Poi.attribute_names.map(&:to_sym) + [:address, :category_ids]
      @batch_limit = PoiServices::SoliguideIndex::BATCH_LIMIT
    end

    def create_all
      find_all_iterator do |page|
        responses = post_all_for_page(page)
        unchanged, to_import = partition_unchanged(responses)

        (touch_unchanged_pois(unchanged) + to_import).each do |response|
          import_poi(response)
        rescue => e
          Rails.logger.error("type=soliguide_importer error: class=#{e.class} message=#{e.message.inspect} source_id=#{response[:source_id]}")
        end
      end

      remove_deprecated_pois
    end

    private

    # Soliguide gives no way to fetch a diff of what changed since the last sync, but each
    # place carries its own `updatedAt`. We store it locally so unchanged places can be
    # skipped instead of being fully reformatted/revalidated/reindexed on every run.
    #
    # This lookup is an optimization, not a correctness requirement: if it fails (e.g. a
    # statement timeout under load right after a big write, when planner stats are stale),
    # fall back to treating the whole page as "to import" rather than aborting the sync.
    def partition_unchanged responses
      existing = Poi.source_soliguide.where(source_id: responses.map { |response| response[:source_id] })
        .pluck(:source_id, :source_updated_at, :validated).to_h { |source_id, source_updated_at, validated| [source_id, [source_updated_at, validated]] }

      responses.partition do |response|
        source_updated_at, validated = existing[response[:source_id]]

        validated && source_updated_at.present? && source_updated_at == response[:source_updated_at]
      end
    rescue => e
      Rails.logger.error("type=soliguide_importer error: class=#{e.class} message=#{e.message.inspect} during partition_unchanged, importing full page")

      [[], responses]
    end

    # Returns the responses that still need a full import, because the bulk touch failed
    # (same fallback rationale as partition_unchanged above).
    def touch_unchanged_pois responses
      return [] if responses.empty?

      Poi.source_soliguide.where(source_id: responses.map { |response| response[:source_id] }).update_all(updated_at: Time.zone.now)

      []
    rescue => e
      Rails.logger.error("type=soliguide_importer error: class=#{e.class} message=#{e.message.inspect} during touch_unchanged_pois, importing full page instead")

      responses
    end

    def import_poi response
      response[:category_ids] = [DEFAULT_CATEGORY_ID] if response[:category_ids].blank?

      poi = Poi.find_or_initialize_by(source_id: response[:source_id])
      poi.update(response.slice(*poi_attributes))
      poi.source = :soliguide
      poi.validated = true
      poi.updated_at = Time.zone.now

      unless poi.save
        Rails.logger.error("type:soliguide_importer error: poi not saved: #{poi.errors.full_messages} (#{response[:source_id]})")
      end
    end

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
      PoiServices::SoliguideIndex.post_all_for_page(page, :long)
    end

    def nb_results
      @nb_results ||= JSON.parse(find_all_query.read_body)['nbResults']
    rescue => e
      Rails.logger.error("type=soliguide_importer error: class=#{e.class} message=#{e.message.inspect}")

      1
    end
  end
end
