require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Gzip compression
  config.middleware.use Rack::Deflater

  # Reloading
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Serving static files (let NGINX/Apache handle this)
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Asset compression
  config.assets.js_compressor = :terser
  # config.assets.css_compressor = :sass

  # Precompiled assets only
  config.assets.compile = false

  # Asset versioning (manuelle pour purge)
  config.assets.version = '2.0'

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  # Force SSL in production
  # config.force_ssl = true

  # Logging configuration
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # i18n fallback
  config.i18n.fallbacks = true

  # Disable deprecation reporting
  config.active_support.report_deprecations = false

  # Schema dump after migrations
  config.active_record.dump_schema_after_migration = false

  # ActionMailer config
  if EnvironmentHelper.staging?
    config.action_mailer.delivery_method = :safety_mailer
    config.action_mailer.safety_mailer_settings = {
      allowed_matchers: [ /@entourage\.social\z/, /\Aabn\.audit\.[123]@advens\.fr\z/ ],
      delivery_method: :smtp,
      delivery_method_settings: {
        port: '587',
        address: 'in-v3.mailjet.com',
        user_name: ENV['MAILJET_API_KEY'],
        password: ENV['MAILJET_SECRET_KEY'],
        authentication: :plain
      }
    }

    ENV['REQUEST_PHONE_CHANGE_CHANNEL'] = '#test-env-sms'
    ENV['ENTOURAGE_SOLIGUIDE_HOST'] = 'https://entourage-soliguide-preprod.herokuapp.com/api/v1/pois'
  else
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      port: '587',
      address: 'in-v3.mailjet.com',
      user_name: ENV['MAILJET_API_KEY'],
      password: ENV['MAILJET_SECRET_KEY'],
      authentication: :plain
    }

    ENV['REQUEST_PHONE_CHANGE_CHANNEL'] = '#moderation-signalements'
    ENV['ENTOURAGE_SOLIGUIDE_HOST'] = 'https://entourage-soliguide-preprod.herokuapp.com/api/v1/pois'
  end

  # DNS rebinding protection (exemple à adapter)
  # config.hosts = [
  #   "entourage.social",
  #   /.*\.entourage\.social/
  # ]
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
