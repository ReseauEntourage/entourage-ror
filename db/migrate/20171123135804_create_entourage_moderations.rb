class CreateEntourageModerations < ActiveRecord::Migration
  def change
    create_table :entourage_moderations do |t|
      t.integer :entourage_id, null: false

      t.boolean :moderated, default: false, null: false

      t.string :action_author_type
      t.string :action_recipient_type
      t.string :action_type
      t.string :action_recipient_consent_obtained

      t.date   :moderated_at
      t.string :moderation_contact_channel
      t.string :moderator
      t.string :moderation_action
      t.text   :moderation_comment

      t.date   :action_outcome_reported_at
      t.string :action_outcome
      t.string :action_success_reason
      t.string :action_failure_reason
    end

    add_index :entourage_moderations, :entourage_id, unique: true
  end
end
