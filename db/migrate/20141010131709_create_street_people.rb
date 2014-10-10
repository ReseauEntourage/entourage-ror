class CreateStreetPeople < ActiveRecord::Migration
  def change
    create_table :street_people do |t|
      t.string :name
      t.string :description
      t.string :language
      t.string :usual_location
      t.timestamps
    end
  end
end
