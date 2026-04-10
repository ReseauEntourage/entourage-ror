class RemoveReportPromptStatusFromJoinRequests < ActiveRecord::Migration[7.1]
  def change
    remove_column :join_requests, :report_prompt_status
  end
end
