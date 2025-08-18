class AddParticipateAtToJoinRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :join_requests, :participate_at, :datetime, default: nil
    add_index :join_requests, :participate_at
  end
end
