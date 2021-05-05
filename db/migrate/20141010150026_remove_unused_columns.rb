class RemoveUnusedColumns < ActiveRecord::Migration[4.2]
  def change
  	remove_column :encounters, :group_id
  end
end
