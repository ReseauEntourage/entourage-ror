class AddBirthdayToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :birthday, :string, limit: 5
  end

  def down
    remove_column :users, :birthday
  end
end
