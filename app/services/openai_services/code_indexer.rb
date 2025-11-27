module OpenaiServices
  class CodeIndexer
    BATCH = 50

    def initialize
      @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    end

    def reindex_all!
      CodeChunk.delete_all

      CodeChunker.collect_chunks.each_slice(BATCH) do |batch|
        contents = batch.map { |chunk| chunk[:content] }

        embeddings = @client.embeddings(
          parameters: {
            model: "text-embedding-3-small",
            input: contents
          }
        )["data"]

        batch.each_with_index do |chunk, idx|
          vector = "[#{embeddings[idx]["embedding"].join(",")}]"

          CodeChunk.create!(
            filepath: chunk[:filepath],
            start_line: chunk[:start_line],
            end_line: chunk[:end_line],
            content: chunk[:content],
            embedding: vector
          )
        end
      end
    end
  end
end
