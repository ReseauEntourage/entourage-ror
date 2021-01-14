class AddLocalEntityToOrganization < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :local_entity, :string, null: true
    add_column :organizations, :email,        :string, null: true
    add_column :organizations, :website_url,  :string, null: true
  end
end
