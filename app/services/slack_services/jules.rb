module SlackServices
  class Jules
    def initialize(text:)
      @text = text
    end

    def answer
      # Strip the bot mention if present
      question = @text.gsub(/<@U[A-Z0-9]+>/, '').strip

      # In a real implementation, this would call OpenAI with codebase context.
      # For now, we simulate the analysis or provide a curated response if possible.

      client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

      # We could provide a system prompt with codebase info
      system_prompt = <<~PROMPT
        You are Jules, a technical assistant for the Entourage Rails project.
        You have knowledge of the codebase.
        The outings API is at Api::V1::OutingsController.
        It uses OutingsServices::Finder with filters: q, latitude, longitude, travel_distance, within_days, interests.
      PROMPT

      response = client.chat(
        parameters: {
          model: "gpt-4",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: question }
          ],
          temperature: 0.7,
        }
      )

      response.dig("choices", 0, "message", "content") || "I'm sorry, I couldn't process that question."
    rescue => e
      Rails.logger.error "Jules Error: #{e.message}"
      "An error occurred while Jules was thinking."
    end
  end
end
