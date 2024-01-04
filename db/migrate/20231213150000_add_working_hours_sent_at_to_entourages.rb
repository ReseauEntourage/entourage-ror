class AddWorkingHoursSentAtToEntourages < ActiveRecord::Migration[6.1]
  def change
    add_column :entourages, :working_hours_sent_at, :datetime, null: true, default: nil
  end
end
