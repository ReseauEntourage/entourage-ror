class AddDeletedToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :deleted, :boolean, null: false, default: false
  end
end
