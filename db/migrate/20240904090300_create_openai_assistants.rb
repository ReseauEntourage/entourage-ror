class CreateOpenaiAssistants < ActiveRecord::Migration[6.1]
  def change
    create_table :openai_assistants do |t|
      t.string :instance_type, null: false
      t.integer :instance_id, null: false

      t.string :openai_assistant_id
      t.string :openai_thread_id
      t.string :openai_run_id
      t.string :openai_message_id
      t.string :status
      t.timestamp :run_starts_at
      t.timestamp :run_ends_at

      t.timestamps null: false

      t.index [:instance_type, :instance_id]
    end
  end
end
