class AddConfirmedAtToJoinRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :join_requests, :confirmed_at, :datetime, default: nil
    add_index :join_requests, :confirmed_at
  end
end
