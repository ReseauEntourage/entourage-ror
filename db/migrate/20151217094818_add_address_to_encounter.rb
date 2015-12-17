class AddAddressToEncounter < ActiveRecord::Migration
  def change
    add_column :encounters, :address, :string, null: true
  end
end
