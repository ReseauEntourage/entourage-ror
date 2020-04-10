class AddUuidToUsers < ActiveRecord::Migration
  def change
    enable_extension :pgcrypto
    add_column :users, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_index :users, :uuid, unique: true
  end
end
