module MatchingServices
  # Hybrid matching of an action:
  # 1. candidates selected in SQL around the place of the action (Candidates)
  # 2. ranked by closeness of meaning (embeddings), distance, freshness and category (Scorer)
  # 3. the shortlist is reranked and explained by a language model (Reranker),
  #    or explained by a template when the model is disabled or fails
  #
  # The run is recorded on the openai_request of the action, as the former OpenAI assistant runs were.
  class Performer
    MAX_MATCHINGS = Reranker::MAX_RECOMMANDATIONS

    attr_reader :openai_request, :instance, :configuration

    def initialize openai_request:
      @openai_request = openai_request
      @instance = openai_request.fetch_instance
      @configuration = OpenaiAssistant.find_by_module_type(:matching)
    end

    def perform
      openai_request.update_columns(run_starts_at: Time.current, updated_at: Time.current)

      candidates_finder = Candidates.new(instance, configuration)
      candidates = candidates_finder.all

      vectors = EmbeddingServices::Store.new(client: client).vectors_for([instance] + candidates.map(&:record))

      return handle_failure('Action has no text to match') unless action_vector = vectors[instance]

      candidates = candidates.select { |candidate| vectors[candidate.record] }
      candidates.each do |candidate|
        candidate.similarity = EmbeddingServices::Store.similarity(action_vector, vectors[candidate.record])
        candidate.score = Scorer.score(candidate, candidates_finder.travel_distance)
      end

      shortlist = Scorer.shortlist(candidates)

      return handle_failure('No candidate') if shortlist.empty?

      recommandations, rerank = recommend(shortlist)

      save_matchings(recommandations)
      handle_success(recommandations, rerank, candidates)
    rescue => e
      handle_failure(e.message)
    end

    def self.rerank_enabled?
      ENV['MATCHING_RERANK'] != 'false'
    end

    private

    def client
      @client ||= OpenAI::Client.new(access_token: configuration&.api_key.presence || ENV['OPENAI_API_KEY'], request_timeout: 120)
    end

    # @return [recommandations, rerank details]
    def recommend shortlist
      return [templated(shortlist), { enabled: false }] unless self.class.rerank_enabled?

      reranker = Reranker.new(client: client)
      recommandations = reranker.rerank(prompt, shortlist)

      [recommandations, { enabled: true, model: Reranker::MODEL, response_id: reranker.response_id }]
    rescue => e
      [templated(shortlist), { enabled: true, model: Reranker::MODEL, response_id: reranker&.response_id, error: e.message }]
    end

    def templated shortlist
      shortlist.first(MAX_MATCHINGS).map do |candidate|
        { candidate: candidate, explanation: Explanation.for(candidate) }
      end
    end

    # the prompt of the back-office describes the action; the instructions of the model are in Reranker
    def prompt
      action_type = instance.contribution? ? 'contribution' : 'solicitation'
      template = configuration&.prompt.presence || 'J\'ai créé une {{action_type}} "{{name}}" : {{description}}'

      template
        .gsub('{{action_type}}', action_type)
        .gsub('{{opposite_action_type}}', action_type == 'contribution' ? 'solicitation' : 'contribution')
        .gsub('{{name}}', instance.name.to_s)
        .gsub('{{description}}', Mentionable.no_html(instance.description.to_s))
    end

    # a new run replaces the matchings of the previous one
    def save_matchings recommandations
      Matching.transaction do
        Matching.where(instance: instance).delete_all

        recommandations.each_with_index do |recommandation, index|
          Matching.create!(
            instance: instance,
            match: recommandation[:candidate].record,
            score: recommandation[:candidate].score.round(3),
            explanation: recommandation[:explanation],
            position: index
          )
        end
      end
    end

    def handle_success recommandations, rerank, candidates
      openai_request.update_columns(
        error: rerank[:error],
        response: {
          engine: 'hybrid',
          rerank: rerank,
          candidates: candidates.group_by(&:type).transform_values(&:count),
          recommandations: recommandations.map { |recommandation| summary(recommandation) }
        }.to_json,
        status: :success,
        run_ends_at: Time.current,
        updated_at: Time.current
      )
    end

    def handle_failure error
      openai_request.update_columns(
        error: error,
        status: :error,
        run_ends_at: Time.current,
        updated_at: Time.current
      )
    end

    def summary recommandation
      candidate = recommandation[:candidate]

      {
        type: candidate.type,
        id: candidate.record.id.to_s,
        name: candidate.record.name,
        score: candidate.score.round(3),
        similarity: candidate.similarity.round(3),
        distance_km: candidate.distance_km&.round(1),
        explanation: recommandation[:explanation]
      }
    end
  end
end
