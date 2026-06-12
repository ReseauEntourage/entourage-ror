class CreateUserNextSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :user_next_steps do |t|
      t.references :user, null: false, foreign_key: true
      t.references :next_step_suggestion, null: false, foreign_key: true
      t.string :status, null: false, default: 'active'
      t.datetime :shown_at
      t.datetime :acted_at
      t.datetime :dismissed_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :user_next_steps, [:user_id, :status]
  end
end
