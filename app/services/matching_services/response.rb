module MatchingServices
  # response example
  # {"recommandations"=>
  #   [{
  #     "type"=>"resource",
  #     "id"=>"e8bWJqPHAcxY",
  #     "name"=>"Sophie : les portraits des bénévoles",
  #     "score"=>"0.96",
  #     "explanation"=>"Ce ressource présente des histoires de bénévoles et peut vous inspirer pour obtenir de l'aide."
  #   }]
  # }

  Response = Struct.new(:response) do
    TYPES = %w{contribution solicitation outing resource poi}

    def initialize(response: nil)
      @response = response
      @parsed_response = parsed_response
    end

    def valid?
      recommandations.any?
    end

    def parsed_response
      return unless @response
      return unless content = @response["content"]
      return unless content.any? && first_content = content[0]
      return unless first_content["type"] == "text"
      return unless value = first_content["text"]["value"]&.gsub("\n", "")
      return unless json = value[/\{.*\}/m]

      JSON.parse(json)
    end

    def recommandations
      return [] unless @parsed_response

      @parsed_response["recommandations"]
    end

    def metadata
      {
        message_id: @response["id"],
        assistant_id: @response["assistant_id"],
        thread_id: @response["thread_id"],
        run_id: @response["run_id"]
      }
    end

    def best_recommandation
      each_recommandation do |instance, score, explanation, index|
        return {
          instance: instance,
          score: score,
          explanation: explanation,
          index: index,
        }
      end
    end

    def each_recommandation &block
      recommandations.each_with_index do |recommandation, index|
        next unless recommandation["id"]
        next unless TYPES.include?(recommandation["type"])
        next unless instance = recommandation["type"].classify.constantize.find_by_id_or_uuid(recommandation["id"])

        yield(instance, recommandation["score"], recommandation["explanation"], index)
      end
    end
  end
end
