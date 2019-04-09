class AddActionTargetTypeToEntourageModerations < ActiveRecord::Migration
  def change
    add_column :entourage_moderations, :action_target_type, :string
  end
end
