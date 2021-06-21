class CreateUserHistories < ActiveRecord::Migration[4.2]
  def up
    create_table :user_histories do |t|
      t.integer :user_id, null: false
      t.integer :updater_id
      t.string :kind, null: false
      t.jsonb :metadata, default: {}

      t.timestamps null: false

      t.index :user_id
      t.index :updater_id
      t.index :kind
    end
  end

  def down
    remove_index :user_histories, :user_id
    remove_index :user_histories, :updater_id
    remove_index :user_histories, :kind

    drop_table :user_histories
  end
end

