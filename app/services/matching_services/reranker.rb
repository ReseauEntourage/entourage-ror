module MatchingServices
  # Asks a language model to rerank the shortlist and to explain each recommandation in one sentence.
  # The model only sees the action and the shortlist (10 candidates at most), never the whole database.
  class Reranker
    class Error < StandardError; end

    MODEL = ENV.fetch('OPENAI_MATCHING_MODEL', 'gpt-6-luna')
    MAX_RECOMMANDATIONS = 5
    DESCRIPTION_LENGTH = 300

    INSTRUCTIONS = <<~TEXT
      Tu aides Entourage, un réseau solidaire qui crée du lien entre des personnes en situation de précarité ou d'isolement et leurs voisins.

      Une personne vient de publier une action : une demande d'aide (solicitation) ou une offre d'aide (contribution). Tu reçois cette action et une liste de candidats déjà présélectionnés près de chez elle : actions de sens opposé, événements (outing), groupes (neighborhood), lieux solidaires (poi) et ressources pédagogiques (resource). La distance est en kilomètres depuis le lieu de l'action.

      Classe les candidats du plus utile au moins utile pour cette personne et écarte ceux qui n'ont pas de rapport avec son action. Garde au plus #{MAX_RECOMMANDATIONS} candidats. Pour chacun, écris une explication d'une phrase, en français, qui s'adresse à la personne en la vouvoyant et qui dit concrètement en quoi ce candidat peut l'aider. Ne cite que des candidats de la liste, avec leur type et leur identifiant exacts.
    TEXT

    TEXT_FORMAT = {
      type: 'json_schema',
      name: 'matching_rerank',
      strict: true,
      schema: {
        type: 'object',
        properties: {
          recommandations: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                type: { type: 'string', enum: %w[contribution solicitation outing neighborhood poi resource] },
                id: { type: 'string' },
                explanation: { type: 'string' }
              },
              required: %w[type id explanation],
              additionalProperties: false
            }
          }
        },
        required: ['recommandations'],
        additionalProperties: false
      }
    }.freeze

    attr_reader :client, :response_id

    def initialize client:
      @client = client
    end

    # @return [{ candidate:, explanation: }], best first
    def rerank prompt, candidates
      response = client.responses.create(parameters: {
        model: MODEL,
        instructions: INSTRUCTIONS,
        input: [{ role: 'user', content: [
          { type: 'input_text', text: prompt },
          { type: 'input_text', text: { candidats: candidates.map { |candidate| payload(candidate) } }.to_json }
        ] }],
        text: { format: TEXT_FORMAT },
        max_output_tokens: 4_000,
        store: false
      })

      @response_id = response['id']

      raise Error, "status #{response['status']}: #{response.dig('error', 'message') || response.dig('incomplete_details', 'reason')}" unless response['status'] == 'completed'

      recommandations(output_json(response), candidates)
    end

    private

    def payload candidate
      record = candidate.record

      {
        type: candidate.type,
        id: record.id.to_s,
        name: record.name,
        description: description(record)&.truncate(DESCRIPTION_LENGTH),
        distance_km: candidate.distance_km&.round(1),
        date: (Candidates.starts_at(record)&.to_date&.iso8601 if candidate.type == 'outing'),
        category: (record.category&.name if candidate.type == 'poi')
      }.compact
    end

    def description record
      text = record.is_a?(Resource) ? record.text_description_only : record.description

      Mentionable.no_html(text.to_s).squish.presence
    end

    def output_json response
      text = response['output']
        .select { |item| item['type'] == 'message' }
        .flat_map { |item| item['content'] || [] }
        .select { |content| content['type'] == 'output_text' }
        .map { |content| content['text'] }
        .join

      JSON.parse(text)
    rescue JSON::ParserError
      raise Error, 'response is not valid JSON'
    end

    def recommandations json, candidates
      by_key = candidates.index_by { |candidate| [candidate.type, candidate.record.id.to_s] }

      Array(json['recommandations'])
        .map { |item| { candidate: by_key[[item['type'], item['id'].to_s]], explanation: item['explanation'].to_s.strip } }
        .select { |recommandation| recommandation[:candidate] && recommandation[:explanation].present? }
        .uniq { |recommandation| recommandation[:candidate] }
        .first(MAX_RECOMMANDATIONS)
    end
  end
end
