class UpdateUserAddress < ActiveRecord::Migration
  def change
    change_table :addresses do |t|
      t.rename :name, :place_name
      t.rename :formatted_address, :street_address
      t.column :google_place_id, :string
    end
  end
end
