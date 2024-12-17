module OpenaiServices
  class BasicResponse
    def initialize response: nil
      @response = response
      @parsed_response = parsed_response
    end

    def valid?
      raise NotImplementedError, "this method valid? has to be defined in your class"
    end

    def display_result
      raise NotImplementedError, "this method display_result has to be defined in your class"
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

    def to_json
      @response.to_json
    end

    def metadata
      {
        message_id: @response["id"],
        assistant_id: @response["assistant_id"],
        thread_id: @response["thread_id"],
        run_id: @response["run_id"]
      }
    end
  end
end
