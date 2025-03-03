module OpenaiServices
  # response example
  # {"recommandations"=>
  #   [{
  #     "type"=>"resource",
  #     "id"=>"e8bWJqPHAcxY",
  #     "name"=>"Sophie : les portraits des bénévoles",
  #     "score"=>"0.96",
  #     "explanation"=>"Cette ressource présente des histoires de bénévoles et peut vous inspirer pour obtenir de l'aide."
  #   }]
  # }

  class MatchingResponse < BasicResponse
    TYPES = %w{contribution solicitation outing resource poi}

    def valid?
      recommandations.any?
    end

    def display_result
      recommandations.count
    end

    def recommandations
      return [] unless @parsed_response

      @parsed_response["recommandations"]
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
        next unless instance = recommandation["type"].classify.constantize.find_by_id(recommandation["id"])

        yield(instance, recommandation["score"], recommandation["explanation"], index)
      end
    end
  end
end
