connection = ActiveRecord::Base.connection
res = connection.execute("select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE'")
tables = res.map(&:values).flatten
res.clear

counts = {}
tables.each do |table|
  res = connection.execute("select count(*) from public.#{table}")
  counts[table] = res[0]['count'].to_i
  res.clear
rescue ActiveRecord::StatementInvalid => e
  puts e
end

counts.sort_by(&:last).each do |table, count|
  puts "#{table}: #{count}"
end
