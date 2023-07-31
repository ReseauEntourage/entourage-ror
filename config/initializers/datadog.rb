# https://docs.datadoghq.com/tracing/setup_overview/setup/ruby/#quickstart-for-rails-applications

if EnvironmentHelper.staging? || EnvironmentHelper.production?
  Datadog.configure do |c|
    c.service = 'entourage-backend'

    # This will activate auto-instrumentation for Rails
    c.tracing.instrument :rails, analytics_enabled: true, service_name: 'entourage-backend', log_injection: true

    # add sidekiq integration
    c.tracing.instrument :sidekiq, analytics_enabled: true, service_name: 'sidekiq'
  end
end
