require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EntourageBack
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Set the application's time zone
    config.time_zone = 'Paris'

    # Configure the default locale
    config.i18n.default_locale = :fr

    # Configure autoload/eager_load for lib
    config.autoload_lib(ignore: %w(assets tasks))

    # Configure generators
    config.generators do |g|
      g.fixture_replacement :factory_bot
      g.test_framework :rspec
      g.view_specs false
      g.helper_specs false
      g.routing_specs false
      g.factory_bot dir: 'spec/factories'
    end

    # Controllers
    # api::v1::basecontroller defines after_action :set_completed_route on actions that may not exists in the controller
    config.action_controller.raise_on_missing_callback_actions = false

    # ActiveJob adapter
    config.active_job.queue_adapter = :sidekiq

    # Observers
    config.active_record.observers = [
      :entourage_denorm_observer,
      :user_block_observer,
      :join_request_observer,
      :push_notification_trigger_observer,
      :translation_observer,
      :denorm_chat_message_observer,
      :smalltalk_observer,
      :smalltalk_membership_observer
    ]

    # Default URL options
    Rails.application.routes.default_url_options[:host] = ENV['HOST']
    config.action_mailer.default_url_options = { host: ENV['HOST'] }

    # Lograge setup
    config.lograge.enabled = true
    config.lograge.custom_options = lambda do |event|
      payload = event.payload
      params = payload[:params].reject { |k| ['controller', 'action'].include? k }

      {
        params: params,
        platform: payload[:platform],
        version: payload[:version],
        user: payload[:user],
        ip: payload[:ip],
        API_KEY: payload[:api_key],
        request_id: payload[:request_id],
      }
    end
    config.lograge.formatter = Lograge::Formatters::Logstash.new

    # Load custom environment helpers
    require File.join(Rails.root, 'app/services/environment_helper')

    # Skylight probes
    if defined?(Skylight)
      config.skylight.probes += %w(active_model_serializers excon faraday redis)
    end

    # Enable GC profiling
    GC::Profiler.enable
  end
end
