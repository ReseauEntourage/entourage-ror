module EmbeddingServices
  # Returns the embedding of each record, embedding only the records that have none or whose text changed since.
  # Records are embedded lazily, when they are first used as a matching candidate: there is no backfill to run.
  class Store
    MODEL = 'text-embedding-3-small'
    DIMENSIONS = 512
    BATCH_SIZE = 500
    # rows written per statement: 340 vectors in one statement took 1 s against the 2 s statement timeout of production
    UPSERT_SLICE = 50

    attr_reader :client

    def initialize client:
      @client = client
    end

    # @return { record => [Float] } for every record with a text
    def vectors_for records
      texts = records.uniq.each_with_object({}) do |record, hash|
        text = Text.for(record)
        hash[record] = text if text
      end

      return {} if texts.empty?

      digests = texts.transform_values { |text| digest(text) }
      stored = stored_embeddings(texts.keys)

      vectors = {}
      missing = []

      texts.each_key do |record|
        embedding = stored[[record.class.polymorphic_name, record.id]]

        if embedding && embedding.digest == digests[record]
          vectors[record] = embedding.vector
        else
          missing << record
        end
      end

      missing.each_slice(BATCH_SIZE) do |batch|
        embed(batch.map { |record| texts[record] }).each_with_index do |vector, index|
          vectors[batch[index]] = vector
        end

        save(batch, digests, vectors)
      end

      vectors
    end

    def self.similarity vector_a, vector_b
      # embeddings are normalized: their dot product is their cosine similarity
      vector_a.each_with_index.sum { |value, index| value * vector_b[index] }
    end

    private

    def digest text
      Digest::SHA256.hexdigest("#{MODEL}:#{DIMENSIONS}:#{text}")
    end

    def stored_embeddings records
      records.group_by { |record| record.class.polymorphic_name }.flat_map do |type, records_of_type|
        Embedding.where(embeddable_type: type, embeddable_id: records_of_type.map(&:id)).to_a
      end.index_by { |embedding| [embedding.embeddable_type, embedding.embeddable_id] }
    end

    def embed texts
      response = client.embeddings(parameters: { model: MODEL, dimensions: DIMENSIONS, input: texts })

      response['data'].sort_by { |data| data['index'] }.map { |data| data['embedding'] }
    end

    def save records, digests, vectors
      records.each_slice(UPSERT_SLICE) do |slice|
        Embedding.upsert_all(slice.map { |record|
          {
            embeddable_type: record.class.polymorphic_name,
            embeddable_id: record.id,
            model: MODEL,
            digest: digests[record],
            vector: vectors[record]
          }
        }, unique_by: [:embeddable_type, :embeddable_id], update_only: [:model, :digest, :vector])
      end
    end
  end
end
