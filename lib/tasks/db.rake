namespace :db do
  desc "Refresh materialized view"
  task refresh_sales_summary: :environment do
    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW monthly_outings")
    puts "Materialized view monthly_outings has been refreshed."
  end
end
