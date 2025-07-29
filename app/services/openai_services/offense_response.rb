module OpenaiServices
  class OffenseResponse < BasicResponse
    def valid?
      %w[true false].include?(result.to_s)
    end

    def offensive?
      'true' == result.to_s
    end

    def display_result
      result
    end

    def result
      return unless @parsed_response.present?

      @parsed_response['result']
    end
  end
end
