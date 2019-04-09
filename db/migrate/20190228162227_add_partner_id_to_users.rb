class AddPartnerIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :partner_id, :integer
    add_index  :users, :partner_id
  end
end
