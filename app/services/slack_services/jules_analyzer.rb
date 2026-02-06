module SlackServices
  class JulesAnalyzer
    def initialize(text:)
      @text = text
    end

    def answer
      # Strip the bot mention if present
      question = @text.gsub(/<@U[A-Z0-9]+>/, '').strip

      # Use Google Gemini API (representing the Jules integration)
      # Endpoint changed to v1 stable as v1beta might not support the model in all regions/keys

      api_key = ENV['GOOGLE_AI_API_KEY']
      return "Jules API key is missing." if api_key.blank?

      system_prompt = <<~PROMPT
        You are Jules, a technical assistant for the Entourage Rails project.
        You have knowledge of the codebase.
        The outings API is at Api::V1::OutingsController.
        It uses OutingsServices::Finder with filters: q, latitude, longitude, travel_distance, within_days, interests.
      PROMPT

      response = HTTParty.post(
        "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=#{api_key}",
        headers: { "Content-Type" => "application/json" },
        body: {
          contents: [
            {
              role: "user",
              parts: [
                { text: "#{system_prompt}\n\nUser Question: #{question}" }
              ]
            }
          ],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 1000
          }
        }.to_json
      )

      if response.success?
        response.dig("candidates", 0, "content", "parts", 0, "text") || "I'm sorry, I couldn't process that question."
      else
        Rails.logger.error "Jules (Gemini) Error: #{response.body}"
        # Fallback error message
        "An error occurred while Jules was thinking. (API Error: #{response.code})"
      end
    rescue => e
      Rails.logger.error "Jules Error: #{e.message}"
      "An error occurred while Jules was thinking."
    end
  end
end
