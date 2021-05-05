class UpdateAudienceLengthToPois < ActiveRecord::Migration[4.2]
  def change
    change_column :pois, :audience, :string, length: 1023
  end
end
