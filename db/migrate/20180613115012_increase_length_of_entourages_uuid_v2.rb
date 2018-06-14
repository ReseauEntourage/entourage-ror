class IncreaseLengthOfEntouragesUuidV2 < ActiveRecord::Migration
  def up
    change_column :entourages, :uuid_v2, :string, limit: 71
  end

  def down
    change_column :entourages, :uuid_v2, :string, limit: 12
  end
end
