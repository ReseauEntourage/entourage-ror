require 'barnes'

workers Integer(ENV['WEB_CONCURRENCY'] || 1)
threads_count = Integer(ENV['MAX_THREADS'] || 10)
threads threads_count, threads_count

preload_app!

port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

pidfile ENV['PUMA_PIDFILE'] if ENV['PUMA_PIDFILE']

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end

before_fork do
  Barnes.start # Must have enabled worker mode for this to block to be called
end

lowlevel_error_handler do |e, env|
  Sentry.capture_exception(e)
  [500, {}, ["An error has occurred, and engineers have been informed. Please reload the page. If you continue to have problems, contact contact@entourage.social\n"]]
end
