class AddIndexOnPushTokenToUserApplications < ActiveRecord::Migration[4.2]
  def change
    add_index :user_applications, :push_token
  end
end
