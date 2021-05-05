class AddActionTargetTypeToEntourageModerations < ActiveRecord::Migration[4.2]
  def change
    add_column :entourage_moderations, :action_target_type, :string
  end
end
