source 'https://rubygems.org'

ruby '3.1.0'

gem 'rails',                          '~> 7.0.0'

gem 'sass-rails'
gem 'uglifier'
gem 'terser'
gem 'jquery-rails',                   '~> 4'
gem 'jquery-ui-rails',                '~> 5'
gem 'turbolinks',                     '~> 5'
gem 'coffee-rails',                   '~> 5'
gem 'active_model_serializers',       '~> 0.10'
gem 'handlebars_assets',              '~> 0'
gem 'geocoder',                       '~> 1'
gem 'rpush',                          '~> 7'
gem 'aws-sdk-sns',                    '~> 1'
gem 'nexmo'
gem 'googlestaticmap',                git: 'https://github.com/ReseauEntourage/googlestaticmap.git'
gem 'momentjs-rails',                 '~> 2'
gem 'shorturl',                       '~> 1.0.0'
gem 'attr_encrypted',                 '~> 3'
gem 'mailchimp-api',                  '~> 2'
gem 'pg',                             '~> 1'
gem 'kaminari',                       '~> 1'
gem 'redis',                          '~> 4'
gem 'bcrypt',                         '~> 3'
gem 'sidekiq',                        '~> 6'
gem 'simplify_rb',                    '~> 0'
gem 'lograge'
gem 'logstash-event'
gem 'aws-sdk-s3',                     '~> 1'
gem 'faker'
gem 'activerecord-postgis-adapter',   '~> 8.0'
gem 'slack-notifier'
gem 'mailjet'
gem 'safety_mailer'
gem 'ransack',                        '~> 2'
gem 'mixpanel-ruby'
gem 'httparty'
gem 'sentry-raven'
gem 'ruby-stemmer'
gem 'json-schema',                    '~> 2.8.1'
gem 'icalendar'
gem 'phonelib'
gem 'whenever'
gem 'ddtrace', '~> 1.0' # we may need to add "require: 'ddtrace/auto_instrument'" to get more components
gem 'airrecord',                      '~> 1'
gem 'select2-rails'
gem 'rails-observers'
gem 'mini_magick'
gem 'rspec_api_documentation'
gem 'ams_lazy_relationships'
gem 'acts-as-taggable-on',            '~> 9.0'
gem 'ancestry'
gem 'tinymce-rails'

group :development, :test do
  # gem 'annotate'
  # gem 'byebug',                       '~> 5.0.0'
  gem 'spring',                       '~> 2.1.0'
  gem 'spring-commands-rspec'#,        '~> 1.0.4'
  gem 'dotenv-rails'#,                 '~> 2.0.2'
  gem 'rails-controller-testing'
end

group :development do
  # gem 'rack-mini-profiler',           '~> 0.10.1' #enable by requesting any page with '?pp=enable'
  # gem 'pry-rails',                    '~> 0.3.4'
  gem 'bullet'#,                       '~> 4.14.7'
  # gem 'thin',                         '~> 1.6.3'
  # gem 'better_errors',                '~> 2.1.1'
  # gem 'binding_of_caller',            '~> 0.8.0'
  # gem 'derailed_benchmarks'
  # gem 'stackprof',                    '~> 0.2.8'
  # gem 'letter_opener',                '~> 1.4.1'
  # gem 'mailcatcher'
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'rspec-rails'#,                  '~> 3.8'
  gem 'shoulda-matchers'#,             '~> 3.0.1'
  gem 'timecop'#,                      '~> 0.8.0'
  gem 'factory_bot_rails',           '~> 4'
  gem 'webmock'
  gem 'fakeredis'#,                    '~> 0.7.0'
  gem 'super_diff',                    '~> 0.9.0' # 0.10.0 requires rails 6, ruby 3
end

group :production do
  gem 'rails_12factor'
  gem 'rails_stdout_logging'
  gem 'puma'
  gem 'rack-timeout', require: 'rack/timeout/base'
  gem 'barnes'
end
