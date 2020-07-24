source 'https://rubygems.org'

ruby '2.6.5'

gem 'rails',                          '~> 4.2.11.3'

# custom version of rack with backported security fixes
gem 'rack', git: 'https://github.com/rails-lts/rack.git', branch: 'lts-1-6-stable'

gem 'sass-rails',                     '~> 4.0.3'
gem 'uglifier',                       '>= 1.3.0'
gem 'jquery-rails',                   '~> 4.0.4'
gem 'jquery-ui-rails',                '~> 5.0.5'
gem 'turbolinks',                     '~> 2.5.3'
gem 'active_model_serializers',       '~> 0.9.3'
gem 'handlebars_assets',              '~> 0.20.2'
gem 'geocoder',                       '~> 1.6.1'
gem 'rpush'
gem 'aws-sdk-sns',                    '~> 1'
gem 'nexmo'
gem 'googlestaticmap',                git: 'https://github.com/ReseauEntourage/googlestaticmap.git'
gem 'momentjs-rails',                 '~> 2.10.3'
gem 'shorturl',                       '~> 1.0.0'
gem 'attr_encrypted',                 '~> 1.3.4'
gem 'mailchimp-api',                  '~> 2.0.6'
gem 'pg',                             '~> 0.21'
gem 'newrelic_rpm',                   '~> 5.6.0'
gem 'kaminari',                       '~> 1.2.1'
gem 'redis',                          '~> 4.1.0'
gem 'bcrypt',                         '~> 3.1.10'
gem 'sidekiq',                        '~> 3.4.1'
gem 'simplify_rb',                    '~> 0.1.2'
gem 'lograge'
gem 'logstash-event'
gem 'aws-sdk-s3',                     '~> 1'
gem 'faker',                          '~> 1.6.1'
gem 'activerecord-postgis-adapter',   '~> 3.1.4'
gem 'slack-notifier'
gem 'mailjet'
gem 'safety_mailer'
gem 'ransack'
gem 'mixpanel-ruby'
gem 'httparty'
gem 'sentry-raven'
gem 'ruby-stemmer'
gem 'json-schema',                    '~> 2.8.1'
gem 'icalendar'
gem 'phonelib'

group :development, :test do
  gem 'annotate'
  gem 'byebug',                       '~> 5.0.0'
  gem 'spring',                       '~> 2.0.2'
  gem 'spring-commands-rspec',        '~> 1.0.4'
  gem 'dotenv-rails',                 '~> 2.0.2'
end

group :development do
  gem 'rack-mini-profiler',           '~> 0.10.1' #enable by requesting any page with '?pp=enable'
  gem 'pry-rails',                    '~> 0.3.4'
  gem 'bullet',                       '~> 4.14.7'
  gem 'thin',                         '~> 1.6.3'
  gem 'better_errors',                '~> 2.1.1'
  gem 'binding_of_caller',            '~> 0.8.0'
  gem 'derailed_benchmarks'
  gem 'stackprof',                    '~> 0.2.8'
  gem 'letter_opener',                '~> 1.4.1'
  gem 'mailcatcher'
end

group :test do
  gem 'rspec-rails',                  '~> 3.8'
  gem 'shoulda-matchers',             '~> 3.0.1'
  gem 'timecop',                      '~> 0.8.0'
  gem 'factory_girl_rails',           '~> 4.5.0'
  gem 'webmock'
  gem 'fakeredis',                    '~> 0.7.0'
  gem 'test_after_commit'
  gem 'super_diff'
end

group :production do
  gem 'rails_12factor'
  gem 'rails_stdout_logging'
  gem 'puma'
  gem 'rack-timeout', require: 'rack/timeout/base'
  gem 'barnes'
  gem 'skylight'
end
