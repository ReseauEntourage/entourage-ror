require 'raven'

Raven.configure do |config|
  config.dsn = ENV["SENTRY_DNS"]
  config.environments = %w[ production ]
  config.excluded_exceptions = ['ActionController::ParameterMissing']
end