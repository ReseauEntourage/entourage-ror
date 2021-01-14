class AddAttributesToEncounter < ActiveRecord::Migration[4.2]
  def change
   	add_column :encounters, :street_person_name, :string
  	add_column :encounters, :message, :text
  end
end
