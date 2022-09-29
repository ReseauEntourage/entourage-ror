class AddStatusToResources < ActiveRecord::Migration[5.2]
  def up
    add_column :addresses, :city, :string
  end

  def down
    remove_column :addresses, :city
  end
end
