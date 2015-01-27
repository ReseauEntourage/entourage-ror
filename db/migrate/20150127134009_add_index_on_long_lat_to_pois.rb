class AddIndexOnLongLatToPois < ActiveRecord::Migration
  def change
    add_index :pois, [:latitude, :longitude]
  end
end
