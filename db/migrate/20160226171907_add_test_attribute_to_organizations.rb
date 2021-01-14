class AddTestAttributeToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :test_organization, :boolean, null: false, default: false
  end
end
