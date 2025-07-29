namespace :redis do
  desc 'database_cleanup'
  task database_cleanup: :environment do
    redis.keys('rpush:notifications:*').each do |key|
      next unless redis.ttl(key) == -1
      next unless redis.type(key) == 'hash'
      next if redis.hget(key, 'delivered').nil?
      redis.expire(key, 24.hours.to_i)
    end
  end
end
