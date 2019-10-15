class AddArchivedAtToJoinRequests < ActiveRecord::Migration
  def change
    add_column :join_requests, :archived_at, :datetime
  end
end
