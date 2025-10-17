class ChangeUsersPartnerIdIndexToPartialIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :users, :partner_id, if_exists: true

    add_index :users, :partner_id,
      name: :index_users_on_partner_id_not_null,
      where: "partner_id IS NOT NULL"
  end
end
