require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#halting-callback-chains-via-throw-abort
# ActiveSupport.halt_callback_chains_on_return_false = false

module EntourageBack
  class Application < Rails::Application
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = 'Paris'

    # Batch loading
    config.middleware.use BatchLoader::Middleware
    config.load_defaults 5.0

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :fr

     config.generators do |g|
       g.fixture_replacement :factory_bot
       g.test_framework :rspec
       g.view_specs false
       g.helper_specs false
       g.routing_specs false
       g.factory_bot dir: 'spec/factories'
     end

    config.active_job.queue_adapter = :sidekiq

    config.active_record.observers = [:entourage_denorm_observer, :user_block_observer, :join_request_observer, :push_notification_trigger_observer, :translation_observer, :denorm_chat_message_observer, :smalltalk_observer, :smalltalk_membership_observer]

    Rails.application.routes.default_url_options[:host] = ENV['HOST']
    config.action_mailer.default_url_options = { host: ENV['HOST'] }

    # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#per-form-csrf-tokens
    # config.action_controller.per_form_csrf_tokens = true

    config.tinymce.install = :copy

    # lograge
    # note: development.rb overrides this config
    config.lograge.enabled = true
    config.lograge.custom_options = lambda do |event|
      payload = event.payload

      params = payload[:params].reject do |k|
        ['controller', 'action'].include? k
      end

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

    require File.join(Rails.root, 'app/services/environment_helper')

    if defined?(Skylight)
      # https://www.skylight.io/support/advanced-setup#probes
      config.skylight.probes += %w(active_model_serializers excon faraday redis)
    end

    #Enabling Profiling on GC
    GC::Profiler.enable
  end
end
