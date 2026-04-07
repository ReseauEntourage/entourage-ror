class RemoveDefaultCoordinatesFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :default_latitude
    remove_column :users, :default_longitude
  end
end
