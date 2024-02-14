namespace :db do
  task :stats do
    connection = ActiveRecord::Base.connection
    counts = {}

    connection.tables.map do |table|
      result = ActiveRecord::Base.connection.execute("select count(*) from #{table}")
      counts[table] = result.entries.first['count'].to_i
      result.clear
    end

    counts.sort_by(&:last).each do |table, count|
      puts "#{table}: #{count}"
    end
  end
end
