class RemoveUnusedIndexes < ActiveRecord::Migration[6.1]
  def change
    remove_index :entourages, [:latitude, :longitude]
    remove_index :entourages, [:community, :group_type]
    remove_index :user_recommandations, [:completed_at, :skipped_at]

    add_index :entourages, :group_type
  end
end
