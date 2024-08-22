require 'json'
require 'open3'

class BertJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :lexical_transformations

  def perform lexical_transformation_id, with_callbacks = true
    lexical_transformation = LexicalTransformation.find(lexical_transformation_id)

    return unless instance = lexical_transformation.instance
    return unless text = Bertable.bert_concatenated_fields_for(instance)

    [:vectors_minilm_l6, :vectors_minilm_l12].each do |column|
      next unless embedded = embedding(column, text)
      next unless embedded.present?

      if with_callbacks
        lexical_transformation.update("#{column}": embedded)
      else
        lexical_transformation.update_columns("#{column}": embedded, updated_at: Time.current)
      end
    end
  end

  def self.perform_later lexical_transformation_id, with_callbacks = true
    BertJob.perform_async(lexical_transformation_id, with_callbacks)
  end

  def embedding column, text
    command = "python3 pycall/#{column}.py \"#{Shellwords.escape(text)}\""
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

