class RemoveUnusedColumns < ActiveRecord::Migration
  def change
  	remove_column :encounters, :group_id
  end
end
