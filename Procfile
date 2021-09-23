web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-10} -q default -q mailers -q broadcast -q denorm
release: ACTIVERECORD_STATEMENT_TIMEOUT=90s bundle exec rake db:migrate
