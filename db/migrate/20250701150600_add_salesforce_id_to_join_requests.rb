class AddSalesforceIdToJoinRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :join_requests, :salesforce_id, :string
  end
end
