class CreateAssistantActions < ActiveRecord::Migration[7.1]
  def change
    # One row per action that the AI assistant asks Local to run on behalf of a user: it makes
    # the action idempotent (unique key per user) and traceable (subject of the action).
    # No foreign key to users, like next_steps: the rows are deleted by AssistantAccountObserver
    # when the account is deleted or anonymized.
    create_table :assistant_actions do |t|
      t.integer :user_id, null: false
      # uuid of the preview that the person confirmed, sent in the Idempotency-Key header
      t.string :idempotency_key, null: false
      t.string :action_type, null: false
      # digest of the content of the request, to detect a key reused for another request
      t.string :request_digest, null: false
      # processing, succeeded or failed
      t.string :status, null: false, default: 'processing'
      # identifiers and statuses only, never the text of a message or of a publication
      t.jsonb :result, null: false, default: {}
      # the object created or modified by the action
      t.string :subject_type
      t.integer :subject_id

      t.timestamps
    end

    add_index :assistant_actions, [:user_id, :idempotency_key], unique: true, name: 'index_assistant_actions_on_user_id_and_idempotency_key'
    add_index :assistant_actions, [:subject_type, :subject_id], name: 'index_assistant_actions_on_subject'
  end
end
