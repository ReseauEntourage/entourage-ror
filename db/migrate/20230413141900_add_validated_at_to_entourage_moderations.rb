class AddValidatedAtToEntourageModerations < ActiveRecord::Migration[5.2]
  def up
    add_column :entourage_moderations, :validated_at, :datetime
  end

  def down
    remove_column :entourage_moderations, :validated_at
  end
end

