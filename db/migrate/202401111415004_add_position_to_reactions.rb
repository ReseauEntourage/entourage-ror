class AddPositionToReactions < ActiveRecord::Migration[6.1]
  def change
    add_column :reactions, :position, :integer, default: 0
  end
end
