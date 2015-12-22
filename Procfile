web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c 10 -q default -q mailers