class AddAttributesToPois < ActiveRecord::Migration
  def change
  	add_column :pois, :adress, :string 
  	add_column :pois, :phone, :string 
  	add_column :pois, :website, :string 
  	add_column :pois, :email, :string 
  	add_column :pois, :audience, :string
  end
end
