class AddUuidV2ToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :uuid_v2, :string, limit: 12

    execute <<-SQL
      update neighborhoods set uuid_v2 = left(MD5(random()::text), 12);
    SQL

    change_column :neighborhoods, :uuid_v2, :string, limit: 12, null: false

    add_index :neighborhoods, :uuid_v2, unique: true
  end

  def down
    remove_index :neighborhoods, :uuid_v2

    remove_column :neighborhoods, :uuid_v2
  end
end
