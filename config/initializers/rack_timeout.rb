if Rails.env.production?
  #Abort request that takes too long to execute, see https://devcenter.heroku.com/articles/request-timeout#timeout-behavior
  Rack::Timeout.service_timeout = ENV["RACK_TIMEOUT"].try(:to_i) || 5
  Rack::Timeout::Logger.level  = Logger::WARN
end
