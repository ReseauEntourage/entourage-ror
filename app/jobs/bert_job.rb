require 'json'
require 'open3'

class BertJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :lexical_transformations

  def perform lexical_transformation_id, field
    lexical_transformation = LexicalTransformation.find(lexical_transformation_id)
    instance = lexical_transformation.instance

    return unless instance.respond_to?(field)
    return unless text = instance.send(field)
    return unless lexical_transformation.respond_to?(field)
    return unless embedded = embedding(text)
    return unless embedded.present?

    lexical_transformation.update("#{field}": embedded)
  end

  def self.perform_later lexical_transformation_id, field
    return unless field

    BertJob.perform_async(lexical_transformation_id, field.to_s)
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

