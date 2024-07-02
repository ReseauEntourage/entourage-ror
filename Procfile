web: bundle exec puma -C config/puma.rb
worker_staging: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-10} -q sms -q salesforce -q translation -q mailers -q default -q broadcast -q denorm
release: ACTIVERECORD_STATEMENT_TIMEOUT=90s bundle exec rake db:migrate
