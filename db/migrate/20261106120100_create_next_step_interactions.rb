class CreateNextStepInteractions < ActiveRecord::Migration[7.1]
  def change
    # Append-only log of what the apps report about suggestions.
    create_table :next_step_interactions do |t|
      t.integer :user_id, null: false
      # null for a suggestion shown among the "others"
      t.integer :next_step_id
      # hero or others
      t.string :placement, null: false
      # displayed, why_opened or tapped
      t.string :kind, null: false
      t.string :item_kind
      t.string :target_type
      t.integer :target_id
      t.datetime :created_at, null: false
    end

    add_index :next_step_interactions, [:user_id, :created_at], name: 'index_next_step_interactions_on_user_id_and_created_at'
    add_index :next_step_interactions, :next_step_id, name: 'index_next_step_interactions_on_next_step_id'
  end
end
