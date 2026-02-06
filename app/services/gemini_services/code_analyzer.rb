module GeminiServices
  class CodeAnalyzer
    def initialize question
      @question = question
    end

    def analyze
      api_key = ENV['GOOGLE_AI_API_KEY']
      return "Jules API key is missing." if api_key.blank?

      system_prompt = <<~PROMPT
        You are Jules, a technical assistant for the Entourage Rails project.
        You have knowledge of the codebase.
        Analyze the question and return an answer based on the analysis of this code
      PROMPT

      response = HTTParty.post(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=#{api_key}",
        headers: { "Content-Type" => "application/json" },
        body: {
          contents: [
            {
              role: "user",
              parts: [
                { text: "#{system_prompt}\n\nUser Question: #{@question}" }
              ]
            }
          ],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 8192
          }
        }.to_json,
        timeout: 60
      )


      return {
        success: false,
        error: "Gemini Error: #{response.body}"
      } unless response.success?

      {
        success: true,
        answer: response.dig("candidates", 0, "content", "parts", 0, "text") || "I'm sorry, I couldn't process that question."
      }
    rescue => e
      {
        success: false,
        error: "An error occurred while Jules was thinking: #{e.message}"
      }
    end
  end
end
