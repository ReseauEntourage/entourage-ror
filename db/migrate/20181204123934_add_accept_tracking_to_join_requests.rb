class AddAcceptTrackingToJoinRequests < ActiveRecord::Migration
  def change
    add_column :join_requests, :requested_at, :datetime
    add_column :join_requests, :accepted_at, :datetime
  end
end
