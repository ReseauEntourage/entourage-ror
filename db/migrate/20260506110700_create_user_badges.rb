class CreateUserBadges < ActiveRecord::Migration[7.1]
  def up
    unless table_exists?(:user_badges)
      create_table :user_badges do |t|
        t.integer :user_id, null: false
        t.string :badge_tag, null: false
        t.boolean :active, default: true, null: false
        t.datetime :awarded_at, null: false
        t.jsonb :metadata, default: {}, null: false
        t.timestamps
      end

      add_index :user_badges, [:user_id, :badge_tag], unique: true
    end
  end

  def down
    drop_table :user_badges if table_exists?(:user_badges)
  end
end
