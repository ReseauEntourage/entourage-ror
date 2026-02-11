class RenameUserPhoneChangesPhoneWas < ActiveRecord::Migration[7.1]
  def change
    rename_column :user_phone_changes, :phone_was, :previous_phone
  end
end

