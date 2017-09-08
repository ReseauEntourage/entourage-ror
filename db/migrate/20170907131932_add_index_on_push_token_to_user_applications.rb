class AddIndexOnPushTokenToUserApplications < ActiveRecord::Migration
  def change
    add_index :user_applications, :push_token
  end
end
