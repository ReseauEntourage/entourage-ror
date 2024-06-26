class AddAddressableToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_column :addresses, :addressable_type, :string, length: 32, default: :null
    add_column :addresses, :addressable_id, :integer, default: :null
  end
end
