class SoftDeleteAtdTables < ActiveRecord::Migration[5.2]
  def up
    rename_column :users, :atd_friend, :old_atd_friend # boolean
    rename_table :atd_synchronizations, :old_atd_synchronizations
    rename_table :atd_users, :old_atd_users
  end

  def down
    rename_table :old_atd_synchronizations, :atd_synchronizations
    rename_table :old_atd_users, :atd_users
    rename_column :users, :old_atd_friend, :atd_friend
  end
end
