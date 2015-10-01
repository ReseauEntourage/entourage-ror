class AddDefaultLatitudeAndDefaultLongitudeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :default_latitude, :float
    add_column :users, :default_longitude, :float
  end
end
