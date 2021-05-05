class AddAcceptTrackingToJoinRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :join_requests, :requested_at, :datetime
    add_column :join_requests, :accepted_at, :datetime
  end
end
