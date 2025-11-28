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
        Tu dois répondre à la question suivante, en t'appuyant UNIQUEMENT sur le code fourni.

        Si tu n'as pas assez d'information pour répondre, dis-le explicitement.

        QUESTION :
        #{question}

        CODE PERTINENT :
        #{context}

        FORMAT ATTENDU DE LA RÉPONSE :
        - Réponse claire en français
        - Ne pas citer les chemins des fichiers
        - Si l'information est incertaine, préciser "incertain"
        - La réponse doit être intelligible pour une personne non développeur
        - La réponse doit être concise (deux ou trois phrases maxi)
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

    def send_to_slack message, channel:, thread_ts:
      Faraday.post(
        "https://slack.com/api/chat.postMessage",
        {
          channel: channel,
          text: message,
          thread_ts: thread_ts,
          blocks: [{
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Réponse :*\n#{message}"
            }
          }]
        }.to_json,
        {
          "Authorization" => "Bearer #{ENV['SLACK_BOT_AI_QUESTION_TOKEN']}",
          "Content-Type" => "application/json"
        }
      )
    end
  end
end
