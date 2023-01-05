class ChangeLengthsToPois < ActiveRecord::Migration[5.2]
  def up
    # soliguide sends long audiences, websites, etc
    change_column :pois, :audience, :string, length: 2048
    change_column :pois, :website, :string, length: 512
  end

  def down
    change_column :pois, :audience, :string, length: 1023
    change_column :pois, :website, :string, length: 255
  end
end
