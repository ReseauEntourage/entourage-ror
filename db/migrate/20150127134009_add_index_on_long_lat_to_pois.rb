class AddIndexOnLongLatToPois < ActiveRecord::Migration[4.2]
  def change
    add_index :pois, [:latitude, :longitude]
  end
end
