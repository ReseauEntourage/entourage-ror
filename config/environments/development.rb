Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  config.force_ssl = false

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raise errors in `after_rollback`/`after_commit`
  config.active_record.raise_in_transactional_callbacks = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # DEV / TEST CREDENTIALS
  #TODO: Remove credentials from sources files
  ENV["BASIC_ADMIN_USER"] = "admin"
  ENV["BASIC_ADMIN_PASSWORD"] = "3nt0ur4g3"

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

  if ENV['LOG_TO_STDOUT'] == 'true'
    config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
  end

  if ENV['LOG_ACTIVE_RECORD_QUERIES'] == 'false'
    config.active_record.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
    config.active_record.logger.level = Logger::INFO
  end

  #Bullet gem config
  config.after_initialize do
    Bullet.enable = ENV['DISABLE_BULLET'] != 'true'
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end
end
