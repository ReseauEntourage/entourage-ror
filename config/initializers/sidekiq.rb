Sidekiq.configure_server do |config|
  ActiveSupport.on_load(:after_initialize) do
    Rpush.embed unless Rails.env.test? || ENV['DISABLE_RPUSH'] == 'true'
  end
end
