module OpenaiServices
  class OffensePerformer < BasicPerformer
    def user_message
      {
        role: "user",
        content: [
          { type: "text", text: get_formatted_prompt },
        ]
      }
    end

    def get_response_class
      OffenseResponse
    end

    private

    def handle_success response
      super(response)

      puts "-- response.offensive?: #{response.offensive?}"

      if response.offensive?
        puts "-- offensive!"
        SlackServices::OffensiveText.new(instance: instance, text: instance.content).notify
      end
    end

    def get_formatted_prompt
      @configuration.prompt.gsub("{{text}}", instance.content)
    end
  end
end
