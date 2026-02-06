module SlackServices
  class JulesAnalyzer
    def initialize(text:)
      @text = text
    end

    def answer
      # Strip the bot mention if present
      question = @text.gsub(/<@U[A-Z0-9]+>/, '').strip

      # Use Google Gemini API (representing the Jules integration)
      # Using 'gemini-1.5-flash' as per user requirement but with better error handling
      # and logging to help debug why it might be "not found"

      api_key = ENV['GOOGLE_AI_API_KEY']
      return "Jules API key is missing." if api_key.blank?

      system_prompt = <<~PROMPT
        You are Jules, a technical assistant for the Entourage Rails project.
        You have knowledge of the codebase.
        The outings API is at Api::V1::OutingsController.
        It uses OutingsServices::Finder with filters: q, latitude, longitude, travel_distance, within_days, interests.
      PROMPT

      model = "gemini-1.5-flash"

      response = HTTParty.post(
        "https://generativelanguage.googleapis.com/v1/models/#{model}:generateContent?key=#{api_key}",
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

        # If model not found, we try gemini-pro as a fallback
        if response.code == 404
          return try_fallback(api_key, system_prompt, question)
        end

        "An error occurred while Jules was thinking. (API Error: #{response.code})"
      end
    rescue => e
      Rails.logger.error "Jules Error: #{e.message}"
      "An error occurred while Jules was thinking."
    end

    private

    def try_fallback(api_key, system_prompt, question)
      Rails.logger.info "Jules: gemini-1.5-flash not found, falling back to gemini-pro"

      response = HTTParty.post(
        "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=#{api_key}",
        headers: { "Content-Type" => "application/json" },
        body: {
          contents: [
            {
              role: "user",
              parts: [
                { text: "#{system_prompt}\n\nUser Question: #{question}" }
              ]
            }
          ]
        }.to_json
      )

      if response.success?
        response.dig("candidates", 0, "content", "parts", 0, "text") || "I'm sorry, I couldn't process that question."
      else
        "Jules is currently unavailable. Please verify the AI model configuration in your Google AI Studio account."
      end
    end
  end
end
