web_backoffice: bundle exec puma -C config/puma_backoffice.rb
web_api: bundle exec puma -C config/puma_api.rb
worker_1: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-2} -q sms -q salesforce -q translation
worker_2: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-10} -q mailers -q default -q openai_assistants -q broadcast -q denorm
release: ACTIVERECORD_STATEMENT_TIMEOUT=90s bundle exec rake db:migrate
