require File.expand_path('../boot', __FILE__)

require 'rails/all'

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
      payload = event.payload

      params = payload[:params].reject do |k|
        ['controller', 'action'].include? k
      end

      if payload[:controller] == 'Api::V1::TourPointsController' &&
         payload[:action]     == 'create' &&
         params['tour_points'] != nil

        tour_points = params['tour_points']
        count = tour_points.count

        params['tour_points'] = [
          tour_points.first,
          ("1 tour_point" if count == 3),
          ("#{count - 2} tour_points" if count >= 4),
          (tour_points.last if count >= 2)
        ].compact
      end

      {
          "params" => params,
          "API_KEY" => payload[:api_key]
      }
    end
    config.log_tags = [ lambda {|req| Time.now.to_s(:db) }, :remote_ip ]

    config.x.mailchimp = config_for(:mailchimp)

    #Enabling Profiling on GC
    GC::Profiler.enable
  end
end
