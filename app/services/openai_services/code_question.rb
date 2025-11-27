module OpenaiServices
  class CodeQuestion
    def initialize
      @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    end

    def answer(question:, code_chunks:)
      context = code_chunks.map.with_index do |chunk, idx|
        <<~CTX
        [#{idx+1}] #{chunk.filepath} (lignes #{chunk.start_line}-#{chunk.end_line})
        #{chunk.content}
        CTX
      end.join("\n\n---\n\n")

      prompt = <<~PROMPT
        Tu es un assistant spécialisé dans l'analyse d'applications Ruby on Rails.
        Tu dois répondre à la question suivante, de manière concise, en t'appuyant UNIQUEMENT sur le code fourni.

        Si tu n'as pas assez d'information pour répondre, dis-le explicitement.

        QUESTION :
        #{question}

        CODE PERTINENT :
        #{context}

        FORMAT ATTENDU DE LA RÉPONSE :
        - Réponse claire en français
        - Si la réponse se trouve dans des fichiers, cite leurs chemins
        - Si l'information est incertaine, préciser "incertain"
      PROMPT

      @client.chat(
        parameters: {
          model: "gpt-4.1",
          messages: [
            { role: "user", content: prompt }
          ],
          temperature: 0.1
        }
      )["choices"][0]["message"]["content"]
    end
  end
end
