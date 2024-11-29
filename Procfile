web: bundle exec puma -C config/puma.rb
worker_1: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-2} -q sms -q salesforce -q translation
worker_2: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-10} -q mailers -q default -q openai_requests -q broadcast -q denorm
release: ACTIVERECORD_STATEMENT_TIMEOUT=90s bundle exec rake db:migrate
