class AddAirConditionedToPois < ActiveRecord::Migration[7.1]
  def change
    add_column :pois, :air_conditioned, :boolean
  end
end
