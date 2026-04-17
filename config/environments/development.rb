require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Action Cable configuration
  config.action_cable.mount_path = "/cable"
  config.action_cable.disable_request_forgery_protection = true
  config.action_cable.allowed_request_origins = [ /.*/ ]

  # Settings specified here will take precedence over those in config/application.rb.
  config.hosts << 'api.entourage.localhost'
  config.hosts << 'admin.entourage.localhost'
  config.hosts << 'entourage.localhost'
  config.hosts << '.entourage.localhost'
  config.hosts << 'localhost'

  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.cache_store = :memory_store
    config.public_file_server.headers = { "Cache-Control" => "public, max-age=172800" }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.active_storage.service = :local
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.active_support.report_deprecations = true
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_job.verbose_enqueue_logs = true
  config.assets.quiet = true
  config.force_ssl = false

  # Dev/test env credentials
  ENV['REQUEST_PHONE_CHANGE_CHANNEL'] = '#test-env-sms'
  ENV['ENTOURAGE_SOLIGUIDE_HOST'] = 'https://localhost:9292/api/v1/pois'

  if ENV['ENABLE_MAILCATCHER']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = { address: 'localhost', port: 1025 }
  else
    config.action_mailer.delivery_method = :file
  end

  config.lograge.custom_options = lambda { |event| { 'params' => event.payload[:params].reject { |k| ['controller', 'action'].include?(k) }, 'API_KEY' => event.payload[:api_key] } }
  config.lograge.formatter = Lograge::Formatters::KeyValue.new

  config.after_initialize do
    Bullet.enable = ENV['DISABLE_BULLET'] != 'true'
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end

  config.action_controller.raise_on_missing_callback_actions = false
end
