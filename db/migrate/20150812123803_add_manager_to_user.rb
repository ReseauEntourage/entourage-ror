class AddManagerToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :manager, :boolean
  end
end
