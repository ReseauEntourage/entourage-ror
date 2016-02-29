class AddTestAttributeToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :test_organization, :boolean, null: false, default: false
  end
end
