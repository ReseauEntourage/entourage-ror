class AddArchivedAtToJoinRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :join_requests, :archived_at, :datetime
  end
end
