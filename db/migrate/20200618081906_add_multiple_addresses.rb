class AddMultipleAddresses < ActiveRecord::Migration[4.2]
  def change
    add_column :addresses, :user_id,  :integer
    add_column :addresses, :position, :integer, default: 1, null: false

    reversible do |dir|
      dir.up do
        execute <<-SQL
          update addresses
          set user_id = users.id
          from users
          where addresses.id = users.address_id
        SQL
        Address.where(user_id: nil).delete_all
        change_column :addresses, :user_id,  :integer, null: false
      end
    end

    add_index :addresses, [:user_id, :position], unique: true
  end
end
