class AddUuidIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :uuid, unique: true, if_not_exists: true
  end
end
