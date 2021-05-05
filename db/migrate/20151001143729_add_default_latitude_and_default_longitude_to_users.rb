class AddDefaultLatitudeAndDefaultLongitudeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :default_latitude, :float
    add_column :users, :default_longitude, :float
  end
end
