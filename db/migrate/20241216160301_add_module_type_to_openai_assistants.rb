class AddModuleTypeToOpenaiAssistants < ActiveRecord::Migration[6.1]
  def change
    add_column :openai_assistants, :module_type, :string, default: :matching
  end
end
