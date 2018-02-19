Raven.configure do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.current_environment = Rails.env
  config.environments = ['production']
  config.rails_activesupport_breadcrumbs = true
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.processors -= [Raven::Processor::PostData]
end
