class AddAreasAndUserGoalsToAnnouncements < ActiveRecord::Migration
  def change
    add_column :announcements, :areas, :jsonb, default: [], null: false
    add_index  :announcements, :areas, using: :gin

    add_column :announcements, :user_goals, :jsonb, default: [], null: false
    add_index  :announcements, :user_goals, using: :gin
  end
end
