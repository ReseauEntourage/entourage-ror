class UpdateUserAddress < ActiveRecord::Migration[4.2]
  def change
    change_table :addresses do |t|
      t.rename :name, :place_name
      t.rename :formatted_address, :street_address
      t.column :google_place_id, :string
    end
  end
end
