# https://docs.datadoghq.com/tracing/setup_overview/setup/ruby/#quickstart-for-rails-applications

Datadog.configure do |c|
  # This will activate auto-instrumentation for Rails
  c.use :rails, { "analytics_enabled" => true, "service_name" => "entourage-backend", "log_injection" => true }
end
