source 'https://rubygems.org'

ruby '3.1.0'

gem 'rails', '~> 6.0'

# database
gem 'pg', '~> 1'
gem 'activerecord-postgis-adapter', '~> 6.0'

# Templating
gem 'terser' # config.assets.js_compressor in production
gem 'sass-rails' # css
gem 'jquery-rails', '~> 4' # js
gem 'jquery-ui-rails', '~> 5' # js
gem 'turbolinks', '~> 5' # html
gem 'momentjs-rails', '~> 2'
gem 'select2-rails'

# models
gem 'active_model_serializers', '~> 0.10'
gem 'ancestry'
gem 'json-schema', '~> 2.8.1'
gem 'rails-observers'
gem 'acts-as-taggable-on', '~> 8.0'
gem 'store_attribute'
gem 'ruby-stemmer' # used by sensitive_word
gem 'mini_magick' # used by S3ImageUploader.resized_image (entourages thumbnails)

# controllers
gem 'ams_lazy_relationships' # used in serializers
gem 'ransack', '~> 2'

# template
gem 'tinymce-rails'
gem 'chartkick'

# datadog & logs
# gem 'ddtrace', '~> 1.0' # we may need to add "require: 'ddtrace/auto_instrument'" to get more components
gem 'lograge'
gem 'logstash-event'
gem 'kaminari', '~> 1'

# servers
gem 'aws-sdk-s3', '~> 1'
gem 'sidekiq', '~> 6'
gem 'redis', '~> 4'
gem 'sentry-raven'

# api
gem 'ruby-openai'
gem 'icalendar'
gem 'google-api-client', '~> 0.53'
gem 'restforce', '~> 7.2.0'
gem 'googlestaticmap', git: 'https://github.com/ReseauEntourage/googlestaticmap.git'

# communication
gem 'rpush', git: 'https://github.com/rpush/rpush.git', ref: '840125aa568740f87e1e4a60f052748ddbe9c668'
gem 'aws-sdk-sns',  '~> 1'
gem 'nexmo'
gem 'safety_mailer'
gem 'mailjet'
gem 'slack-notifier'

# others
gem 'geocoder', '~> 1'
gem 'bcrypt', '~> 3'
gem 'httparty'
gem 'whenever'
gem 'rspec_api_documentation'
gem 'ffi', '>= 1.15', '< 1.17'

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
  gem 'super_diff'
end

group :production do
  gem 'rails_stdout_logging'
  gem 'puma'
  gem 'rack-timeout', require: 'rack/timeout/base'
  gem 'rack-attack'
  gem 'barnes'
end
