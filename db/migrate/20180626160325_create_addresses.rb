class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :name, null: false
      t.string :formatted_address
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :postal_code, limit: 8
      t.string :country, limit: 2

      t.timestamps null: false
    end

    change_table :users do |t|
      t.references :address, index: true, foreign_key: true
    end
  end
end
