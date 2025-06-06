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

      if response.offensive?
        instance.is_offensible! if instance.respond_to?(:is_offensible!)

        SlackServices::OffensiveText.new(chat_message_id: instance.id, text: instance.content).notify
      end
    end

    def get_formatted_prompt
      @configuration.prompt.gsub("{{text}}", instance.content)
    end
  end
end
