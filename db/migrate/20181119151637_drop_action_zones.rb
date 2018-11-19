class DropActionZones < ActiveRecord::Migration
  def change
    remove_index :action_zones, [:country, :postal_code, :user_id]
    remove_index :action_zones, :user_id
    drop_table :action_zones
  end
end
