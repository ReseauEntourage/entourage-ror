class AddInstanceClassToOpenaiAssistants < ActiveRecord::Migration[6.1]
  def change
    add_column :openai_assistants, :instance_class, :string, default: "Entourage"
  end
end
