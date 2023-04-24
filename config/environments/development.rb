require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.hosts << "admin.entourage.localhost"

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  config.force_ssl = false

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # DEV / TEST CREDENTIALS
  #TODO: Remove credentials from sources files

  ENV['REQUEST_PHONE_CHANGE_CHANNEL'] = '#test-env-sms'
  ENV['ENTOURAGE_SOLIGUIDE_HOST'] = 'https://localhost:9292/api/v1/pois'

  if ENV['ENABLE_MAILCATCHER']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings   = { :address => "localhost", :port => 1025 }
  elsif ENV['ENABLE_MAILJET'] == 'true'
    config.action_mailer.delivery_method = :safety_mailer

    config.action_mailer.safety_mailer_settings = {
      allowed_matchers: [ /@entourage\.social\z/ ],
      delivery_method: :smtp,
      delivery_method_settings: {
        :port =>           '587',
        :address =>        'in-v3.mailjet.com',
        :user_name =>      ENV['MAILJET_API_KEY'],
        :password =>       ENV['MAILJET_SECRET_KEY'],
        :authentication => :plain
      }
    }
  else
    config.action_mailer.delivery_method = :file
  end

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # lograge: override default config from application.rb
  config.lograge.custom_options = lambda do |event|
    payload = event.payload

    params = payload[:params].reject do |k|
      ['controller', 'action'].include? k
    end

    {
      "params" => params,
      "API_KEY" => payload[:api_key]
    }
  end
  config.lograge.formatter = Lograge::Formatters::KeyValue.new

  #Bullet gem config
  config.after_initialize do
    Bullet.enable = ENV['DISABLE_BULLET'] != 'true'
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
end
