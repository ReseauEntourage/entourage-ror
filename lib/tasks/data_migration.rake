namespace :data_migration do
  desc "add longitude, latitude to tours"
  task add_location_to_tours: :environment do
    sql = <<-SQL
      UPDATE tours
      SET longitude = subquery.longitude,
          latitude = subquery.latitude
      FROm (SELECT distinct ON (tour_id) tour_id, longitude, latitude FROM tour_points ORDER BY tour_id, passing_time ASC) AS subquery
      WHERE tours.id = subquery.tour_id
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end
end