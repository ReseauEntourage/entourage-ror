class CreateSurveyResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :survey_responses do |t|
      t.integer :user_id, null: false
      t.integer :chat_message_id, null: false
      t.jsonb :responses, default: []

      t.timestamps null: false

      t.index :user_id
      t.index :chat_message_id
    end
  end
end

