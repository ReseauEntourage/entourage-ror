class AddPartnerFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :partner_admin, :boolean, default: false, null: false
    add_column :users, :partner_role_title, :string
  end
end
