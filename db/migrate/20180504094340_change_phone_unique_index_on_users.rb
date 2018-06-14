class ChangePhoneUniqueIndexOnUsers < ActiveRecord::Migration
  def up
    add_index :users, [:phone, :community], unique: true
    remove_index :users, :phone
  end

  def down
    add_index :users, :phone, unique: true
    remove_index :users, [:phone, :community]
  end
end
