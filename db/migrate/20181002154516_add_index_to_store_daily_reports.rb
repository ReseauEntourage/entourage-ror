class AddIndexToStoreDailyReports < ActiveRecord::Migration[4.2]
  def change
    add_index :store_daily_reports, [:report_date, :app_name,:store_id], unique: true, name: 'index_store_daily_reports_date_store_app'
  end
end
