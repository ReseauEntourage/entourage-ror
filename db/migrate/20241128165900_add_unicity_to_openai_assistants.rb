class AddUnicityToOpenaiAssistants < ActiveRecord::Migration[6.1]
  def change
    remove_index :openai_assistants, [:instance_type, :instance_id]

    add_index :openai_assistants, [:instance_type, :instance_id], unique: true
  end
end
