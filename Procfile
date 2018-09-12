web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-10} -q default -q mailers
release bundle exec rake db:migrate
