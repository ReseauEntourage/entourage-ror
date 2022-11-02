class AddCreationGroupTypeIndexToEntourages < ActiveRecord::Migration[5.2]
  def up
    add_index :entourages, :created_at
    add_index :entourages, [:community,:group_type]
    add_index :join_requests, [:requested_at, :created_at]
  end

  def down
    remove_index :entourages, :created_at
    remove_index :entourages, [:community,:group_type]
    remove_index :join_requests, [:requested_at, :created_at]
  end
end
