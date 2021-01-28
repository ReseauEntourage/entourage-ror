class UpdateAudienceLengthToPois < ActiveRecord::Migration
  def change
    change_column :pois, :audience, :string, length: 1023
  end
end
