require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading is useful in CI to ensure code is loaded as in production
  config.eager_load = ENV["CI"].present?

  # Cache classes (faster test runs)
  config.cache_classes = true

  # Cache compiled views
  config.action_view.cache_template_loading = true

  # Configure public file server with caching headers for performance
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=3600"
  }

  # Show full error reports
  config.consider_all_requests_local = true

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Deliveries are not actually sent
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: 'localhost' }

  # Print deprecation warnings to stderr
  config.active_support.deprecation = :stderr

  # Raise exception for disallowed deprecations
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Log ActiveRecord activity to stdout
  config.active_record.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
  config.active_record.logger.level = Logger::INFO

  # Test-specific ENV variables
  ENV['ANDROID_GCM_API_KEY'] = 'foobar'
  ENV['ENTOURAGE_IMAGES_BUCKET'] = 'foobar'
  ENV['ENTOURAGE_AVATARS_BUCKET'] = 'foobar'
  ENV['ENTOURAGE_AWS_ACCESS_KEY_ID'] = 'foo'
  ENV['ENTOURAGE_AWS_SECRET_ACCESS_KEY'] = 'bar'
  ENV['HOST'] = 'localhost'
  ENV['ORGANIZATION_ADMIN_URL'] = 'localhost'
  ENV['ENTOURAGE_SOLIGUIDE_HOST'] = 'https://localhost:8080/api/v1/pois'

  # Speed up password hashing in test suite
  BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

  # Do not raise error if before_action references non-existent actions
  config.action_controller.raise_on_missing_callback_actions = false

  # Limit slow down due to password hashing
  BCrypt::Engine.cost = BCrypt::Engine::MIN_COST
  # Raises error for missing translations
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with filenames
  # config.action_view.annotate_rendered_view_with_filenames = true
end
