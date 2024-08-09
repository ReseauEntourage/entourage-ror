class BertJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :lexical_transformations

  def perform lexical_transformation_id, field
    lexical_transformation = LexicalTransformation.find(lexical_transformation_id)

    return unless lexical_transformation.respond_to?(field)
    return unless lexical_transformation[field].present?
    return unless embedded = embedding(lexical_transformation[field])

    lexical_transformation.update("#{field}": embedded, performed: true)
  end

  def self.perform_later lexical_transformation_id, field
    BertJob.perform_async(lexical_transformation_id, field)
  end

  def embedding text
    command = "python3 pycall/huggingface_encoder.py \"#{Shellwords.escape(text)}\""
    result = `#{command}`

    JSON.parse(result)
  rescue JSON::ParserError
    nil
  end
end
