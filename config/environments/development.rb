require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Sous-domaines autorisés en dev local
  config.hosts << 'api.entourage.localhost'
  config.hosts << 'admin.entourage.localhost'

  # Reload code on change
  config.enable_reloading = true

  # No eager loading
  config.eager_load = false

  # Show full error reports
  config.consider_all_requests_local = true

  # Enable server timing (nouveauté Rails 7)
  config.server_timing = true

  # Enable/disable caching
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=172800"
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
  config.active_support.report_deprecations = true

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Print enqueue source lines
  config.active_job.verbose_enqueue_logs = true

  # Force SSL off in dev
  config.force_ssl = false

  # Dev/test env credentials
  ENV['REQUEST_PHONE_CHANGE_CHANNEL'] = '#test-env-sms'
  ENV['ENTOURAGE_SOLIGUIDE_HOST'] = 'https://localhost:9292/api/v1/pois'

  # ActionMailer config: Mailcatcher, Mailjet ou fichier local
  if ENV['ENABLE_MAILCATCHER']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings   = { address: 'localhost', port: 1025 }
  elsif ENV['ENABLE_MAILJET'] == 'true'
    config.action_mailer.delivery_method = :safety_mailer

    config.action_mailer.safety_mailer_settings = {
      allowed_matchers: [ /@entourage\.social\z/ ],
      delivery_method: :smtp,
      delivery_method_settings: {
        port: '587',
        address: 'in-v3.mailjet.com',
        user_name: ENV['MAILJET_API_KEY'],
        password: ENV['MAILJET_SECRET_KEY'],
        authentication: :plain
      }
    }
  else
    config.action_mailer.delivery_method = :file
  end

  # Lograge : override config de base
  config.lograge.custom_options = lambda do |event|
    payload = event.payload
    params = payload[:params].reject { |k| ['controller', 'action'].include?(k) }
    {
      'params' => params,
      'API_KEY' => payload[:api_key]
    }
  end
  config.lograge.formatter = Lograge::Formatters::KeyValue.new

  # Bullet gem pour détecter les requêtes N+1
  config.after_initialize do
    Bullet.enable        = ENV['DISABLE_BULLET'] != 'true'
    Bullet.alert         = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
  end

  # Do not raise error if before_action references non-existent actions
  config.action_controller.raise_on_missing_callback_actions = false
end
