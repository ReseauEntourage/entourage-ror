class AddIndexToStoreDailyReports < ActiveRecord::Migration
  def change
    add_index :store_daily_reports, [:report_date, :app_name,:store_id], unique: true, :name => 'index_store_daily_reports_date_store_app'
  end
end
