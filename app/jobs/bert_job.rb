require 'json'
require 'open3'

class BertJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :lexical_transformations

  def perform lexical_transformation_id
    lexical_transformation = LexicalTransformation.find(lexical_transformation_id)

    return unless instance = lexical_transformation.instance
    return unless text = Bertable.bert_concatenated_fields_for(instance)
    return unless embedded = embedding(text)
    return unless embedded.present?

    lexical_transformation.update(vectors: embedded)
  end

  def self.perform_later lexical_transformation_id
    BertJob.perform_async(lexical_transformation_id)
  end

  def embedding(text)
    command = "python3 pycall/huggingface_encoder.py \"#{Shellwords.escape(text)}\""
    stdout, stderr, status = Open3.capture3(command)

    if status.success?
      begin
        JSON.parse(stdout)
      rescue JSON::ParserError
        nil
      end
    else
      Rails.logger.error("Error running python script: #{stderr}")
      nil
    end
  end
end

