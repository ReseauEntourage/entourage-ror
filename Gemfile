source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails',                          '~> 4.2.10'
gem 'sass-rails',                     '~> 4.0.3'
gem 'uglifier',                       '>= 1.3.0'
gem 'jquery-rails',                   '~> 4.0.4'
gem 'jquery-ui-rails',                '~> 5.0.5'
gem 'turbolinks',                     '~> 2.5.3'
gem 'active_model_serializers',       '~> 0.9.3'
gem 'handlebars_assets',              '~> 0.20.2'
gem 'geocoder',                       '~> 1.2.9'
gem 'rpush',                          '~> 2.7.0'
gem 'sinch_sms',                      '~> 2.1'
gem 'googlestaticmap',                git: 'https://github.com/ReseauEntourage/googlestaticmap.git'
gem 'momentjs-rails',                 '~> 2.10.3'
gem 'shorturl',                       '~> 1.0.0'
gem 'attr_encrypted',                 '~> 1.3.4'
gem 'mailchimp-api',                  '~> 2.0.6'
gem 'pg',                             '~> 0.18.2'
gem 'newrelic_rpm',                   '~> 3.12.1.298'
gem 'kaminari',                       '~> 0.16.3'
gem 'redis',                          '~> 3.2.1'
gem 'bcrypt',                         '~> 3.1.10'
gem 'sidekiq',                        '~> 3.4.1'
gem 'simplify_rb',                    '~> 0.1.2'
gem 'lograge',                        '~> 0.3.4'
gem 'aws-sdk',                        '~> 2.2.9'
gem 'faker',                          '~> 1.6.1'
gem 'twitter',                        '~> 5.16.0'
gem 'activerecord-postgis-adapter',   '~> 3.1.4'
gem 'slack-notifier'
gem 'mailjet'
gem 'safety_mailer'
gem 'ransack'
gem 'mixpanel-ruby'
gem 'httparty'
gem 'sentry-raven'
gem 'ruby-stemmer'

group :development, :test do
  gem 'annotate'
  gem 'byebug',                       '~> 5.0.0'
  gem 'spring',                       '~> 1.3.6'
  gem 'spring-commands-rspec',        '~> 1.0.4'
end

group :development do
  gem 'dotenv-rails',                 '~> 2.0.2'
  gem 'rack-mini-profiler',           '~> 0.10.1' #enable by requesting any page with '?pp=enable'
  gem 'pry-rails',                    '~> 0.3.4'
  gem 'bullet',                       '~> 4.14.7'
  gem 'thin',                         '~> 1.6.3'
  gem 'better_errors',                '~> 2.1.1'
  gem 'binding_of_caller',            '~> 0.7.2'
  gem 'derailed',                     '~> 0.1.0'
  gem 'stackprof',                    '~> 0.2.8'
  gem 'letter_opener',                '~> 1.4.1'
  gem 'mailcatcher'
end

group :test do
  gem 'rspec-rails',                  '~> 3.1'
  gem 'shoulda-matchers',             '~> 3.0.1'
  gem 'timecop',                      '~> 0.8.0'
  gem 'factory_girl_rails',           '~> 4.5.0'
  gem 'webmock',                      '~> 1.20.4'
  gem 'coveralls',                    require: false
  gem 'fakeredis',                    '~> 0.5.0'
  gem 'test_after_commit'
end

group :production do
  gem 'rails_12factor',               '~> 0.0.3'
  gem 'rails_stdout_logging',         '~> 0.0.5'
  gem 'puma',                         '~> 2.12.2'
  gem 'rack-timeout',                 '~> 0.4.2'
end
