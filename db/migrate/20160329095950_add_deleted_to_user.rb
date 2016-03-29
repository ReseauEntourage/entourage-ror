class AddDeletedToUser < ActiveRecord::Migration
  def change
    add_column :users, :deleted, :boolean, null: false, default: false
  end
end
