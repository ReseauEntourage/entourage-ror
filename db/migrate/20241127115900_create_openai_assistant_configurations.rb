class CreateOpenaiAssistantConfigurations < ActiveRecord::Migration[6.1]
  def change
    create_table :openai_assistant_configurations do |t|
      t.integer :version, unique: true
      t.string :api_key, null: false
      t.string :assistant_id, null: false

      t.text :prompt, null: false

      t.boolean :poi_from_file, default: false
      t.boolean :resource_from_file, default: false

      t.integer :days_for_actions, default: 30
      t.integer :days_for_outings, default: 30

      t.timestamps null: false
    end
  end
end
