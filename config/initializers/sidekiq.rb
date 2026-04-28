require 'sidekiq-unique-jobs'
require 'sidekiq'
require 'sidekiq/cron/job'

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
    load_sidekiq_cron_jobs
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

def load_sidekiq_cron_jobs
  schedule_file = Rails.root.join('config/sidekiq.yml')

  unless File.exist?(schedule_file)
    Rails.logger.info("No sidekiq.yml schedule file found")
    return
  end

  schedule = YAML.safe_load(
    File.read(schedule_file),
    permitted_classes: [Symbol],
    aliases: true
  )

  cron_config = schedule[:schedule] || schedule['schedule']

  if cron_config.present?
    Sidekiq::Cron::Job.load_from_hash!(cron_config)
    Rails.logger.info("Loaded #{cron_config.size} Sidekiq cron jobs")
  else
    Rails.logger.warn("No Sidekiq cron schedule found in sidekiq.yml")
  end

rescue => e
  Rails.logger.error("Failed to load Sidekiq cron jobs: #{e.message}")
end
