class RenameOpenaiAssistantConfigurationsToOpenaiAssistants < ActiveRecord::Migration[6.1]
  def change
    rename_table :openai_assistant_configurations, :openai_assistants
  end
end
