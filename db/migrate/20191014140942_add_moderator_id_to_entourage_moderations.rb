class AddModeratorIdToEntourageModerations < ActiveRecord::Migration
  def change
    rename_column :entourage_moderations, :moderator, :legacy_moderator
    add_column :entourage_moderations, :moderator_id, :integer
    add_index  :entourage_moderations, :moderator_id
  end
end
