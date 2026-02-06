module SlackServices
  class JulesAnalyzer
    def initialize(text:)
      @text = text
    end

    def answer
      # Strip the bot mention if present
      question = @text.gsub(/<@U[A-Z0-9]+>/, '').strip

      # Use OpenAI to answer the question with project-specific context
      # This represents the "Jules" integration brain.
      client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

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
