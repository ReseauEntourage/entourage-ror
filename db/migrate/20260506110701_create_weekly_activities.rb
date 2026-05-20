class CreateWeeklyActivities < ActiveRecord::Migration[7.1]
  def up
    unless table_exists?(:weekly_activities)
      create_table :weekly_activities do |t|
        t.integer :user_id, null: false
        t.string :week_iso, null: false
        t.boolean :has_group_action, default: false, null: false
        t.timestamps
      end

      add_index :weekly_activities, [:user_id, :week_iso], unique: true
    end
  end

  def down
    drop_table :weekly_activities if table_exists?(:weekly_activities)
  end
end
