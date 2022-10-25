class AddStatusToResources < ActiveRecord::Migration[5.2]
  def up
    add_column :resources, :status, :string, null: false, default: :active
  end

  def down
    remove_column :resources, :status
  end
end
