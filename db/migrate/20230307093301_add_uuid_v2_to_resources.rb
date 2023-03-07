class AddUuidV2ToResources < ActiveRecord::Migration[5.2]
  def up
    add_column :resources, :uuid_v2, :string, limit: 12

    Resource.reset_column_information
    Resource.find_each do |e|
      e.send :set_uuid
      e.save!
    end

    change_column :resources, :uuid_v2, :string, limit: 12, null: false

    add_index :resources, :uuid_v2, unique: true
  end

  def down
    remove_index :resources, :uuid_v2

    remove_column :resources, :uuid_v2
  end
end
