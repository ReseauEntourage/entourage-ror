$redis = Redis.new(url: ENV["HEROKU_REDIS_GOLD_URL"] || ENV["REDIS_URL"], ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
