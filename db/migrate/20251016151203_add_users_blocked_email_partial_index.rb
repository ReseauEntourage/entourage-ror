class AddUsersBlockedEmailPartialIndex < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :email, name: :index_users_blocked_on_email, where: "validation_status = 'blocked'"
  end
end
