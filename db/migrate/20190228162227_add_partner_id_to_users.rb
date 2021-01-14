class AddPartnerIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :partner_id, :integer
    add_index  :users, :partner_id
  end
end
