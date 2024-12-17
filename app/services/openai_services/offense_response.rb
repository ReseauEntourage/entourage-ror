module OpenaiServices
  class OffenseResponse < BasicResponse
    def valid?
      result.in? [true, false]
    end

    def offensive?
      result == true
    end

    def display_result
      result
    end

    def result
      @parsed_response["result"]
    end
  end
end
