redis_url = ENV["HEROKU_REDIS_GOLD_URL"] || ENV["REDIS_URL"]

Sidekiq.configure_server do |config|
  config.redis = {
    url: redis_url,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }

  config.on(:startup) do
    require 'rpush'
    Rpush.configure { |c| c.logger = Logger.new($stdout) }
    Rpush.embed unless Rails.env.test? || ENV['DISABLE_RPUSH'] == 'true'
  end

  config.on(:quiet) { Rpush.try(:shutdown) }
end

Sidekiq.configure_client do |config|
  config.redis = {
      url: redis_url,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end
