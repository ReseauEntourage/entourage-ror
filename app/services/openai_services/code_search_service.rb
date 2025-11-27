module OpenaiServices
  class CodeSearchService
    TOP_K = 8

    def initialize
      @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    end

    def search(question:)
      query_embedding = embedding_for(question)
      vector = "[#{query_embedding.join(",")}]"

      CodeChunk
        .order(Arel.sql("embedding <-> '#{vector}'"))
        .limit(TOP_K)
    end

    private

    def embedding_for(text)
      @client.embeddings(
        parameters: {
          model: "text-embedding-3-small",
          input: text
        }
      )["data"][0]["embedding"]
    end
  end
end
