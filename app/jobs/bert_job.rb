require 'json'
require 'open3'

class BertJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :lexical_transformations

  def perform lexical_transformation_id, field
    lexical_transformation = LexicalTransformation.find(lexical_transformation_id)

    return if lexical_transformation.performed?
    return unless lexical_transformation.respond_to?(field)
    return unless lexical_transformation[field].present?
    return unless embedded = embedding(lexical_transformation[field])

    lexical_transformation.update("#{field}": embedded, performed: true)
  end

  def self.perform_later lexical_transformation_id, field
    BertJob.perform_async(lexical_transformation_id, field)
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

