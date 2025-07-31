redis_url = ENV["HEROKU_REDIS_GOLD_URL"] || ENV["REDIS_URL"]

Sidekiq.configure_server do |config|
  ActiveSupport.on_load(:after_initialize) do
    Rpush.embed unless Rails.env.test? || ENV['DISABLE_RPUSH'] == 'true'
  end

  config.redis = {
    url: redis_url,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
      url: redis_url,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end
