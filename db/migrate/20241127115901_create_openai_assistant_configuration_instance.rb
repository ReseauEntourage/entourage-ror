class CreateOpenaiAssistantConfigurationInstance < ActiveRecord::Migration[6.1]
  def change
    unless Rails.env.test?
      prompt = 'I created a {{action_type}} "{{name}}" : {{description}}. What are the most relevant recommandations? The following text contains all the possible recommandations.'

      # OpenaiAssistantConfiguration.new(
      #   version: 1,
      #   api_key: ENV['OPENAI_API_KEY'],
      #   assistant_id: ENV['OPENAI_API_ASSISTANT_ID'],
      #   prompt: prompt,
      #   poi_from_file: true,
      #   resource_from_file: true,
      #   days_for_actions: 30,
      #   days_for_outings: 30
      # ).save
    end
  end
end
