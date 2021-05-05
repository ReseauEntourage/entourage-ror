class AddReportPromptStatusToJoinRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :join_requests, :report_prompt_status, :string
  end
end
