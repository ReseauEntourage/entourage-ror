class CreateOpenaiOffenseAssistantConfigurationInstance < ActiveRecord::Migration[6.1]
  def change
    unless Rails.env.test?
      OpenaiAssistant.new(
        module_type: :offense,
        version: 2,
        api_key: ENV['OPENAI_API_KEY'],
        assistant_id: ENV['OPENAI_API_OFFENSE_ASSISTANT_ID'],
        prompt: '{{text}}',
        poi_from_file: false,
        resource_from_file: false
      ).save
    end
  end
end
