class CreateStoreDailyReports < ActiveRecord::Migration
  def change
    create_table :store_daily_reports do |t|
      t.string :store_id
      t.string :app_name
      t.date :report_date
      t.integer :nb_downloads

      t.timestamps null: false
    end
  end
end
