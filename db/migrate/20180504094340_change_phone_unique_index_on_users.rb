class ChangePhoneUniqueIndexOnUsers < ActiveRecord::Migration[4.2]
  def up
    add_index :users, [:phone, :community], unique: true
    remove_index :users, :phone
  end

  def down
    add_index :users, :phone, unique: true
    remove_index :users, [:phone, :community]
  end
end
