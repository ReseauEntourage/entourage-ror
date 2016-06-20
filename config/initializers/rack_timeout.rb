#Abort request that takes too long to execute, see https://devcenter.heroku.com/articles/request-timeout#timeout-behavior
Rack::Timeout.service_timeout = ENV["RACK_TIMEOUT"] || 5