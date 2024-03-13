class RemoveIndexJoinRequestsRequestedAt < ActiveRecord::Migration[6.1]
  def change
    # join_requests.requested_at is no longer used
    remove_index :join_requests, [:requested_at, :created_at]
  end
end
