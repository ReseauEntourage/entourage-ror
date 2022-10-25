class AddAreasAndUserGoalsToRecommandations < ActiveRecord::Migration[4.2]
  def change
    add_column :recommandations, :areas, :jsonb, default: [], null: false
    add_index  :recommandations, :areas, using: :gin

    add_column :recommandations, :user_goals, :jsonb, default: [], null: false
    add_index  :recommandations, :user_goals, using: :gin
  end

  def down
    remove_index :recommandations, :areas
    remove_index :recommandations, :user_goals

    remove_column :recommandations, :areas
    remove_column :recommandations, :user_goals
  end
end
