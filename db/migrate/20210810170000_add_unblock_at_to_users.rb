class AddUnblockAtToUsers < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :unblock_at, :datetime, default: nil
    add_index  :users, :unblock_at
  end

  def down
    remove_index :users, :unblock_at
    remove_column :users, :unblock_at
  end
end
