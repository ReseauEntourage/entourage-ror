class RenameUserDenormsToOldUserDenorms < ActiveRecord::Migration[6.1]
  def change
    rename_table :user_denorms, :old_user_denorms
  end
end
