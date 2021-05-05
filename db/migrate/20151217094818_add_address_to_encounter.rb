class AddAddressToEncounter < ActiveRecord::Migration[4.2]
  def change
    add_column :encounters, :address, :string, null: true
  end
end
