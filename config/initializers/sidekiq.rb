require 'sidekiq'
require 'sidekiq-unique-jobs'

redis_url = ENV["HEROKU_REDIS_GOLD_URL"] || ENV["REDIS_URL"]

Sidekiq.configure_server do |config|
  config.redis = {
    url: redis_url,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  config.on(:startup) do
    setup_rpush
  end

  config.on(:quiet) do
    shutdown_rpush
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: redis_url,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

def setup_rpush
  return if Rails.env.test? || ENV['DISABLE_RPUSH'] == 'true'

  require 'rpush'

  Rpush.configure do |c|
    c.logger = Logger.new($stdout)
  end

  Rpush.embed
rescue => e
  Rails.logger.error("Rpush setup failed: #{e.message}")
end

def shutdown_rpush
  Rpush.try(:shutdown)
rescue => e
  Rails.logger.error("Rpush shutdown failed: #{e.message}")
end
