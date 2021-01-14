class AddOrganizationIdToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :organization_id, :integer
  end
end
