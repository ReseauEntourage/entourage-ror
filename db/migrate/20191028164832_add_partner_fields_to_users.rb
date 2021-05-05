class AddPartnerFieldsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :partner_admin, :boolean, default: false, null: false
    add_column :users, :partner_role_title, :string
  end
end
