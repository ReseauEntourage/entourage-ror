class AddReportPromptStatusToJoinRequests < ActiveRecord::Migration
  def change
    add_column :join_requests, :report_prompt_status, :string
  end
end
