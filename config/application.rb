require File.expand_path('../boot', __FILE__)

require 'rails/all'

require File.expand_path('../community', __FILE__)

if Rails.env.in?(%w(development test))
  ENV['COMMUNITY'] ||= 'entourage'
end

raise "Environment variable COMMUNITY must be set" if ENV['COMMUNITY'].blank?
$server_community = Community.new ENV['COMMUNITY']

# Define New Relic app_name dynamically based on $COMMUNITY.
# Can't be done in an initializer because New Relic starts before app initialization.
# examples: "PFP API", "Entourage API (Development)"
new_relic_app_name = "#{$server_community.dev_name} API"
new_relic_app_name += " (#{Rails.env.capitalize})" unless Rails.env.production?
ENV['NEW_RELIC_APP_NAME'] = new_relic_app_name

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EntourageBack
  class Application < Rails::Application
    config.time_zone = 'Paris'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :fr

     config.generators do |g|
       g.fixture_replacement :factory_girl
       g.test_framework :rspec
       g.view_specs false
       g.helper_specs false
       g.routing_specs false
       g.factory_girl dir: 'spec/factories'
     end

    config.active_job.queue_adapter = :sidekiq

    Rails.application.routes.default_url_options[:host] = ENV["HOST"]
    config.action_mailer.default_url_options = { :host => ENV["HOST"] }

    #lograge
    config.lograge.enabled = true
    config.lograge.custom_options = lambda do |event|
      params = event.payload[:params].reject do |k|
        ['controller', 'action'].include? k
      end
      {
          "params" => params,
          "API_KEY" => event.payload[:api_key]
      }
    end
    config.log_tags = [ lambda {|req| Time.now.to_s(:db) }, :remote_ip ]

    #Enabling Profiling on GC
    GC::Profiler.enable
  end
end
