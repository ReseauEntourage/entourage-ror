class AddUuidV2ToResources < ActiveRecord::Migration[5.2]
  def up
    add_column :resources, :uuid_v2, :string, limit: 12

    execute <<-SQL
      update resources set uuid_v2 = left(MD5(random()::text), 12);
    SQL

    change_column :resources, :uuid_v2, :string, limit: 12, null: false

    add_index :resources, :uuid_v2, unique: true
  end

  def down
    remove_index :resources, :uuid_v2

    remove_column :resources, :uuid_v2
  end
end
