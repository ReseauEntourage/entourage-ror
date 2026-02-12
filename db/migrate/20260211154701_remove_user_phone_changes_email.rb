class RemoveUserPhoneChangesEmail < ActiveRecord::Migration[7.1]
  def change
    remove_column :user_phone_changes, :email
  end
end

