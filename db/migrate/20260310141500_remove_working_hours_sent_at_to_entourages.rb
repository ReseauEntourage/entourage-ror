class RemoveWorkingHoursSentAtToEntourages < ActiveRecord::Migration[7.1]
  def change
    remove_column :entourages, :working_hours_sent_at
  end
end
