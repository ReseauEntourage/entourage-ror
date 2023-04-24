require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Turn false under Spring and add config.action_view.cache_template_loading = true.
  config.cache_classes = true

  config.action_view.cache_template_loading = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.i18n.raise_on_missing_translations = true

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  config.active_record.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
  config.active_record.logger.level = Logger::INFO

  # DEV / TEST CREDENTIALS
  ENV["ANDROID_GCM_API_KEY"] = "foobar"

  config.action_mailer.default_url_options = { :host => "localhost" }

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  ENV["ENTOURAGE_IMAGES_BUCKET"]="foobar"
  ENV["ENTOURAGE_AVATARS_BUCKET"]="foobar"
  ENV["ENTOURAGE_AWS_ACCESS_KEY_ID"]="foo"
  ENV["ENTOURAGE_AWS_SECRET_ACCESS_KEY"]="bar"

  ENV["MAILCHIMP_LIST_ID"]="foobar"
  ENV["MAILCHIMP_API_KEY"]="foobar-us8"

  ENV["HOST"]='localhost'
  ENV["ORGANIZATION_ADMIN_URL"]="localhost"
  ENV["ENTOURAGE_SOLIGUIDE_HOST"]="https://localhost:8080/api/v1/pois"

  # Limit slow down due to password hashing
  BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true
end
