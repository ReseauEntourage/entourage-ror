class IncreasePostalCodesLengthTo8 < ActiveRecord::Migration
  def up
    change_column :entourages, :postal_code, :string, limit: 8
    change_column :action_zones, :postal_code, :string, limit: 8, null: false
  end

  def down
    change_column :entourages, :postal_code, :string, limit: 5
    change_column :action_zones, :postal_code, :string, limit: 5, null: false
  end
end
