class CreatePois < ActiveRecord::Migration[4.2]

  def change
    create_table :pois do |t|
      t.string :name
      t.string :poi_type
      t.text :description
      t.float :latitude
      t.float :longitude
      t.timestamps
    end
  end

end
