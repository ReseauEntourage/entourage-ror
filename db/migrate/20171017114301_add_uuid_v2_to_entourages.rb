class AddUuidV2ToEntourages < ActiveRecord::Migration
  def up
    add_column :entourages, :uuid_v2, :string, limit: 12
    Entourage.reset_column_information
    Entourage.find_each do |e|
      e.send :set_uuid
      e.save!
    end
    change_column :entourages, :uuid_v2, :string, limit: 12, null: false
    add_index :entourages, :uuid_v2, unique: true
  end

  def down
    remove_index :entourages, :uuid_v2
    remove_column :entourages, :uuid_v2
  end
end
