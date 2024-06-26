class AddStreetNumberAndRouteToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_column :addresses, :street_number, :string, length: 32, default: :null
    add_column :addresses, :route, :string, length: 128, default: :null
  end
end
