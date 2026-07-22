class CreateScheduledPublications < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_publications do |t|
      t.string :publishable_type, null: false
      t.integer :publishable_id, null: false
      t.integer :neighborhood_id
      t.integer :author_id, null: false
      t.datetime :scheduled_at, null: false
      t.string :status, null: false, default: 'pending'
      t.text :failure_reason
      t.integer :recurrence_rule_id

      t.timestamps
    end

    add_index :scheduled_publications, [:publishable_type, :publishable_id]
    add_index :scheduled_publications, :status
    add_index :scheduled_publications, :scheduled_at
    add_index :scheduled_publications, :neighborhood_id
    add_index :scheduled_publications, :recurrence_rule_id
  end
end
