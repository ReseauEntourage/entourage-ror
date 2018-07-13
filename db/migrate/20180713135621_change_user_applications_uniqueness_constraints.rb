class ChangeUserApplicationsUniquenessConstraints < ActiveRecord::Migration
  def up
    remove_index :user_applications, :push_token
    add_index    :user_applications, :push_token, unique: true

    remove_index :user_applications, [:user_id, :device_os, :version]
    add_index    :user_applications, [:user_id, :device_family]
  end

  def down
    remove_index :user_applications, :push_token
    add_index    :user_applications, :push_token

    remove_index :user_applications, [:user_id, :device_family]
    add_index    :user_applications, [:user_id, :device_os, :version], unique: true
  end
end
