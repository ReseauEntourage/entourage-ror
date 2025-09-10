class ChangeBirthdayLimitInUsers < ActiveRecord::Migration[5.2]
  def up
    change_column :users, :birthday, :string, limit: 10
  end

  def down
    change_column :users, :birthday, :string, limit: 5
  end
end
