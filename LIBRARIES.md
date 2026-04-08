# Libraries

This document lists all gems used in the `entourage-back-preprod` Rails application, organized by purpose.

**Ruby version:** 3.2.0
**Rails version:** ~> 7.1.0

---

## Rails Core & Server

### `rails`

| | |
|---|---|
| **Version** | `7.1.5.2` *(Gemfile: `~> 7.1.0`)* |
| **Release date** | November 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rails](https://rubygems.org/gems/rails) |

Full-stack web application framework providing MVC structure, ORM, routing, and all core Rails components.

**Used in:** Entire application — models, controllers, views, migrations, and background jobs.

**Alternatives:** Sinatra, Hanami, Grape

---

### `puma`

| | |
|---|---|
| **Version** | `7.0.4` |
| **Release date** | January 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/puma](https://rubygems.org/gems/puma) |

Multi-threaded HTTP server for Ruby/Rack applications.

**Used in:** `config/puma.rb` — production web server on Heroku.

**Alternatives:** Unicorn, Passenger, Falcon

---

### `rack-timeout`

| | |
|---|---|
| **Version** | `0.7.0` |
| **Release date** | March 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rack-timeout](https://rubygems.org/gems/rack-timeout) |

Rack middleware that aborts requests that exceed a configurable time limit.

**Used in:** `config/initializers/rack_timeout.rb` — protects against slow requests in production.

**Alternatives:** `rack-timeout` is standard; custom Rack middleware

---

### `rack-attack`

| | |
|---|---|
| **Version** | `6.7.0` |
| **Release date** | January 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rack-attack](https://rubygems.org/gems/rack-attack) |

Rack middleware for rate limiting and IP blocking.

**Used in:** `config/initializers/rack_attack.rb` — throttles login and SMS endpoints; signals attacks to Slack via `SlackServices::SignalRackAttack`.

**Alternatives:** `throttle`, custom Rack middleware

---

### `rails_stdout_logging`

| | |
|---|---|
| **Version** | `0.0.5` |
| **Release date** | 2013 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rails_stdout_logging](https://rubygems.org/gems/rails_stdout_logging) |

Redirects Rails log output to stdout, as required by Heroku's logging infrastructure.

**Used in:** Production environment (`:production` group) — ensures logs are captured by Heroku's log drain.

**Alternatives:** Configure `config.logger` manually

---

### `barnes`

| | |
|---|---|
| **Version** | `0.0.9` |
| **Release date** | 2018 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/barnes](https://rubygems.org/gems/barnes) |

Sends Puma server metrics to Heroku's `statsd` agent for visibility in the Heroku metrics dashboard.

**Used in:** `config/puma.rb` — production metrics reporting.

**Alternatives:** `puma_worker_killer`, custom Datadog integration

---

## Database

### `pg`

| | |
|---|---|
| **Version** | `1.6.2` *(Gemfile: `~> 1.1`)* |
| **Release date** | November 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/pg](https://rubygems.org/gems/pg) |

PostgreSQL adapter for ActiveRecord.

**Used in:** `config/database.yml` — primary database driver for all environments.

**Alternatives:** `mysql2`, `sqlite3`

---

### `activerecord-postgis-adapter`

| | |
|---|---|
| **Version** | `9.0.2` *(Gemfile: `~> 9.0`)* |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/activerecord-postgis-adapter](https://rubygems.org/gems/activerecord-postgis-adapter) |

ActiveRecord adapter with PostGIS spatial type support via RGeo.

**Used in:** `config/database.yml` — enables geospatial column types and spatial queries for location-based features.

**Alternatives:** `spatial_adapter`, raw PostGIS with custom types

---

## Asset Pipeline & Frontend

### `sprockets-rails`

| | |
|---|---|
| **Version** | `3.5.2` *(Gemfile: `~> 3.2`)* |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/sprockets-rails](https://rubygems.org/gems/sprockets-rails) |

Integrates the Sprockets asset pipeline into Rails.

**Used in:** `config/application.rb` — manages CSS and JavaScript asset compilation.

**Alternatives:** Propshaft, Vite Rails

---

### `sass-rails`

| | |
|---|---|
| **Version** | `6.0.0` |
| **Release date** | 2020 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/sass-rails](https://rubygems.org/gems/sass-rails) |

Provides Sass/SCSS support for the Rails asset pipeline via SassC.

**Used in:** Asset pipeline — compiles SCSS stylesheets for the backoffice.

**Alternatives:** `cssbundling-rails`, Tailwind CSS

---

### `terser`

| | |
|---|---|
| **Version** | `1.2.6` |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/terser](https://rubygems.org/gems/terser) |

JavaScript minifier used by Sprockets via ExecJS.

**Used in:** `config/application.rb` — `config.assets.js_compressor = :terser` in production.

**Alternatives:** `uglifier`, `yui-compressor`

---

### `jquery-rails`

| | |
|---|---|
| **Version** | `4.6.0` *(Gemfile: `~> 4`)* |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/jquery-rails](https://rubygems.org/gems/jquery-rails) |

Bundles jQuery and the jQuery UJS driver into the Rails asset pipeline.

**Used in:** Backoffice JavaScript — provides jQuery for DOM manipulation and AJAX.

**Alternatives:** Stimulus, vanilla JS

---

### `jquery-ui-rails`

| | |
|---|---|
| **Version** | `5.0.5` *(Gemfile: `~> 5`)* |
| **Release date** | 2014 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/jquery-ui-rails](https://rubygems.org/gems/jquery-ui-rails) |

Packages jQuery UI widgets and interactions for use in the Rails asset pipeline.

**Used in:** Backoffice — UI widgets (datepickers, drag-and-drop, etc.).

**Alternatives:** Custom CSS/JS components

---

### `turbolinks`

| | |
|---|---|
| **Version** | `5.2.1` *(Gemfile: `~> 5`)* |
| **Release date** | 2018 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/turbolinks](https://rubygems.org/gems/turbolinks) |

Speeds up page navigation by replacing full page reloads with AJAX-based partial page updates.

**Used in:** Backoffice views — faster HTML navigation.

**Alternatives:** Turbo (Hotwire), PJAX

---

### `momentjs-rails`

| | |
|---|---|
| **Version** | `2.29.4.1` *(Gemfile: `~> 2`)* |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/momentjs-rails](https://rubygems.org/gems/momentjs-rails) |

Bundles the Moment.js date/time library into the Rails asset pipeline.

**Used in:** Backoffice JavaScript — date formatting and manipulation.

**Alternatives:** Day.js, Luxon, native Intl API

---

### `select2-rails`

| | |
|---|---|
| **Version** | `4.0.13` |
| **Release date** | 2021 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/select2-rails](https://rubygems.org/gems/select2-rails) |

Bundles the Select2 enhanced select-box library into the Rails asset pipeline.

**Used in:** Backoffice forms — searchable dropdowns and multi-select inputs.

**Alternatives:** Chosen, Tom Select

---

### `tinymce-rails`

| | |
|---|---|
| **Version** | `8.1.2` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/tinymce-rails](https://rubygems.org/gems/tinymce-rails) |

Bundles the TinyMCE rich text editor into the Rails asset pipeline.

**Used in:** Backoffice — WYSIWYG content editing for admin-managed content.

**Alternatives:** Action Text (Trix), CKEditor, Quill

---

### `chartkick`

| | |
|---|---|
| **Version** | `5.2.1` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/chartkick](https://rubygems.org/gems/chartkick) |

Simple Ruby/Rails DSL for rendering charts (line, bar, pie, etc.) in views.

**Used in:** Backoffice dashboard — data visualisation for admin metrics.

**Alternatives:** Highcharts, Chart.js directly

---

## Models & Serialization

### `active_model_serializers`

| | |
|---|---|
| **Version** | `0.10.15` *(Gemfile: `~> 0.10`)* |
| **Release date** | 2021 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/active_model_serializers](https://rubygems.org/gems/active_model_serializers) |

Convention-based JSON serialization layer for Rails APIs.

**Used in:** 63+ serializer classes across the `app/serializers/` directory — formats all API JSON responses.

**Alternatives:** Jbuilder, JSONAPI::Serializer, Blueprinter

---

### `ams_lazy_relationships`

| | |
|---|---|
| **Version** | `0.4.0` |
| **Release date** | 2019 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/ams_lazy_relationships](https://rubygems.org/gems/ams_lazy_relationships) |

Extends ActiveModelSerializers to batch-load associations and avoid N+1 queries.

**Used in:** Serializers (e.g., `ConversationSerializer`) — `include AmsLazyRelationships::Core` to defer and batch relationship loading.

**Alternatives:** `batch-loader`, `graphql-batch`

---

### `ancestry`

| | |
|---|---|
| **Version** | `4.3.3` |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/ancestry](https://rubygems.org/gems/ancestry) |

Stores tree-structured data in a single `ancestry` column using a materialized path strategy.

**Used in:** `ChatMessage` model — `has_ancestry` for threaded/nested message replies.

**Alternatives:** `closure_tree`, `awesome_nested_set`

---

### `acts-as-taggable-on`

| | |
|---|---|
| **Version** | `12.0.0` *(Gemfile: `~> 12.0`)* |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/acts-as-taggable-on](https://rubygems.org/gems/acts-as-taggable-on) |

Adds multi-context tagging to ActiveRecord models.

**Used in:** Model concerns (Concernable, Interestable, Involvable, Orientable, Sectionable) — tags users, entourages, and other records across multiple tag contexts.

**Alternatives:** Custom polymorphic tagging table, `gutentag`

---

### `json-schema`

| | |
|---|---|
| **Version** | `2.8.1` *(Gemfile: `~> 2.8.1`)* |
| **Release date** | 2020 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/json-schema](https://rubygems.org/gems/json-schema) |

Validates Ruby objects/hashes against a JSON Schema draft.

**Used in:** `SchemaValidator` — validates incoming JSON payloads against defined schemas; includes a custom `date-time` format validator.

**Alternatives:** `dry-validation`, `ActiveModel::Validations`

---

### `rails-observers`

| | |
|---|---|
| **Version** | `0.1.5` |
| **Release date** | 2014 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rails-observers](https://rubygems.org/gems/rails-observers) |

Restores the Observer pattern removed from Rails 4+.

**Used in:** `EntourageDenormObserver`, `PushNotificationTriggerObserver`, `DenormChatMessageObserver`, `JoinRequestObserver` — reactive side-effects on model lifecycle events.

**Alternatives:** ActiveRecord callbacks, `wisper`

---

### `store_attribute`

| | |
|---|---|
| **Version** | `2.0.1` |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/store_attribute](https://rubygems.org/gems/store_attribute) |

Typed attributes on top of ActiveRecord's `store`/`store_accessor`, with automatic type casting.

**Used in:** `ChatMessage` model — typed `auto_post_type` and `auto_post_id` attributes stored in a JSON `options` column.

**Alternatives:** `typed_store`, native Rails `attribute` API with JSON column

---

### `ruby-stemmer`

| | |
|---|---|
| **Version** | `3.0.0` |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/ruby-stemmer](https://rubygems.org/gems/ruby-stemmer) |

Ruby bindings for the Snowball/Lingua stemmer library, supporting multiple languages.

**Used in:** `SensitiveWord` model — French-language stemming via `Lingua.stemmer()` to normalise words before offensive-content detection.

**Alternatives:** `stemmify`, custom NLP pipeline

---

### `ransack`

| | |
|---|---|
| **Version** | `4.4.0` *(Gemfile: `~> 4.1`)* |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/ransack](https://rubygems.org/gems/ransack) |

Object-based search and filtering for ActiveRecord, with form helpers for admin UIs.

**Used in:** Admin controllers (`EntouragesController`, `PoisController`) — `.ransack()` for search/filter forms in the backoffice.

**Alternatives:** `searchkick`, `pg_search`, custom scopes

---

## Background Jobs & Caching

### `sidekiq`

| | |
|---|---|
| **Version** | `8.0.8` *(Gemfile: `~> 8`)* |
| **Release date** | January 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/sidekiq](https://rubygems.org/gems/sidekiq) |

Redis-backed background job processing framework for Ruby.

**Used in:** 17+ job classes across the app — asynchronous task processing including notifications, emails, and data sync.

**Alternatives:** GoodJob, Delayed::Job, Resque

---

### `redis`

| | |
|---|---|
| **Version** | `4.8.1` *(Gemfile: `~> 4`)* |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/redis](https://rubygems.org/gems/redis) |

Ruby client for Redis, used as the Sidekiq broker and general cache store.

**Used in:** Sidekiq job queue backend; application-level caching.

**Alternatives:** `redis-client` (lower level), Memcached

---

## Authentication & Security

### `bcrypt`

| | |
|---|---|
| **Version** | `3.1.20` *(Gemfile: `~> 3`)* |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/bcrypt](https://rubygems.org/gems/bcrypt) |

Ruby bindings for the bcrypt password-hashing algorithm, used by `has_secure_password`.

**Used in:** `User` model — password hashing and authentication verification.

**Alternatives:** Argon2 (`argon2` gem), `devise`

---

## API Clients & Integrations

### `ruby-openai`

| | |
|---|---|
| **Version** | `8.3.0` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/ruby-openai](https://rubygems.org/gems/ruby-openai) |

Ruby client for the OpenAI API (completions, embeddings, etc.).

**Used in:** `OpenaiAssistant` and `OpenaiRequest` models — AI-assisted features.

**Alternatives:** `anthropic`, `openai` (official SDK)

---

### `google-api-client`

| | |
|---|---|
| **Version** | `0.53.0` *(Gemfile: `~> 0.53`)* |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/google-api-client](https://rubygems.org/gems/google-api-client) |

Google API client library for Ruby.

**Used in:** `Meeting` model — Google Calendar integration via `Google::Apis::CalendarV3`.

**Alternatives:** `google-apis-calendar_v3` (newer split gem)

---

### `restforce`

| | |
|---|---|
| **Version** | `7.6.0` *(Gemfile: `~> 7.6`)* |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/restforce](https://rubygems.org/gems/restforce) |

Salesforce REST API client for Ruby.

**Used in:** `SalesforceServices::Client` — CRM data synchronisation with Salesforce.

**Alternatives:** `databasedotcom`, direct HTTP via `httparty`

---

### `httparty`

| | |
|---|---|
| **Version** | `0.23.2` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/httparty](https://rubygems.org/gems/httparty) |

Simple HTTP client DSL for Ruby.

**Used in:** `Meeting` model and other service classes — outbound HTTP requests to third-party APIs.

**Alternatives:** `faraday`, `net-http`, `httpx`

---

### `icalendar`

| | |
|---|---|
| **Version** | `2.12.0` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/icalendar](https://rubygems.org/gems/icalendar) |

Generates and parses iCalendar (`.ics`) files per RFC 5545.

**Used in:** `IcalService` — generates calendar event invitations sent to users.

**Alternatives:** `ri_cal`, custom iCal generation

---

### `googlestaticmap`

| | |
|---|---|
| **Version** | `1.2.2` (git: `https://github.com/ReseauEntourage/googlestaticmap.git`, rev: `a8e1b27`) |
| **Release date** | N/A (custom fork) |
| **Changelog / Rubygems** | [github.com/ReseauEntourage/googlestaticmap](https://github.com/ReseauEntourage/googlestaticmap) |

Generates Google Static Maps API URLs; this is a custom fork maintained by Réseau Entourage.

**Used in:** Static map image generation for entourage thumbnails and location previews.

**Alternatives:** Direct Google Static Maps API URL building, `mapbox-sdk`

---

## Push Notifications & SMS

### `rpush`

| | |
|---|---|
| **Version** | `9.1.0` *(Gemfile: `~> 9.1.0`)* |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rpush](https://rubygems.org/gems/rpush) |

Push notification framework supporting APNs (iOS), FCM (Android), and Web Push.

**Used in:** `config/initializers/rpush.rb` — push notification delivery configured with Sidekiq backend.

**Alternatives:** `houston`, direct APNs/FCM HTTP APIs

---

### `apnotic`

| | |
|---|---|
| **Version** | `1.7.2` |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/apnotic](https://rubygems.org/gems/apnotic) |

Apple Push Notification service (APNs) HTTP/2 client.

**Used in:** APN testing and direct APNs connections alongside Rpush.

**Alternatives:** `houston`, `apns-http2`

---

### `aws-sdk-sns`

| | |
|---|---|
| **Version** | `1.106.0` *(Gemfile: `~> 1`)* |
| **Release date** | 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/aws-sdk-sns](https://rubygems.org/gems/aws-sdk-sns) |

AWS SDK client for Amazon Simple Notification Service.

**Used in:** `SmsNotificationService` — sends SMS messages via AWS SNS.

**Alternatives:** `nexmo`/`vonage`, Twilio

---

### `nexmo`

| | |
|---|---|
| **Version** | `7.2.1` |
| **Release date** | 2021 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/nexmo](https://rubygems.org/gems/nexmo) |

Vonage (formerly Nexmo) API client for SMS, voice, and messaging.

**Used in:** Listed as a dependency; may be legacy or conditionally used for SMS alongside `aws-sdk-sns`.

**Alternatives:** `vonage` (official successor gem), `aws-sdk-sns`

---

## Email

### `mailjet`

| | |
|---|---|
| **Version** | `1.8.2` |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/mailjet](https://rubygems.org/gems/mailjet) |

Ruby client and ActionMailer adapter for the Mailjet transactional email API.

**Used in:** `config/initializers/mailjet.rb`, `MailjetMailer` base class, `MailjetController` webhook handling — all transactional email delivery.

**Alternatives:** `sendgrid-ruby`, `postmark-rails`

---

### `safety_mailer`

| | |
|---|---|
| **Version** | `0.1.0` |
| **Release date** | 2014 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/safety_mailer](https://rubygems.org/gems/safety_mailer) |

ActionMailer interceptor that prevents emails from being sent to real addresses in non-production environments.

**Used in:** Mailer configuration — guards against accidental email delivery in staging/development.

**Alternatives:** `letter_opener`, custom ActionMailer interceptor

---

## Storage (AWS / Cloud)

### `aws-sdk-s3`

| | |
|---|---|
| **Version** | `1.199.1` *(Gemfile: `~> 1`)* |
| **Release date** | 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/aws-sdk-s3](https://rubygems.org/gems/aws-sdk-s3) |

AWS SDK client for Amazon S3 object storage.

**Used in:** `S3ImageUploader` — uploads, resizes (via `mini_magick`), and manages entourage thumbnails and user images.

**Alternatives:** `fog-aws`, `carrierwave` with S3 backend

---

### `mini_magick`

| | |
|---|---|
| **Version** | `5.3.1` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/mini_magick](https://rubygems.org/gems/mini_magick) |

Lightweight Ruby wrapper around ImageMagick/GraphicsMagick.

**Used in:** `S3ImageUploader.resized_image` — resizes entourage thumbnails and other images before S3 upload.

**Alternatives:** `vips` (`ruby-vips`), `image_processing`

---

## Search & Filtering

### `kaminari`

| | |
|---|---|
| **Version** | `1.2.2` *(Gemfile: `~> 1`)* |
| **Release date** | 2021 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/kaminari](https://rubygems.org/gems/kaminari) |

Scope-based pagination for ActiveRecord with view helpers.

**Used in:** Admin controllers and API endpoints — `.page()` and `.per()` for paginated responses.

**Alternatives:** `pagy`, `will_paginate`

---

## Geolocation

### `geocoder`

| | |
|---|---|
| **Version** | `1.8.6` *(Gemfile: `~> 1`)* |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/geocoder](https://rubygems.org/gems/geocoder) |

Complete geocoding and reverse geocoding solution for Ruby/Rails.

**Used in:** `PoiServices::PoiGeocoder`, model `reverse_geocoded_by` callbacks — converts addresses to coordinates and vice versa using the Google Maps API.

**Alternatives:** `geokit`, direct Google/Mapbox API calls

---

## Monitoring & Logging

### `sentry-ruby`

| | |
|---|---|
| **Version** | `5.28.0` |
| **Release date** | 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/sentry-ruby](https://rubygems.org/gems/sentry-ruby) |

Official Sentry SDK for Ruby — error tracking, performance monitoring, and breadcrumbs.

**Used in:** `config/initializers/sentry.rb` — captures exceptions, breadcrumbs, and integrates with Geocoder and HTTParty for context.

**Alternatives:** `rollbar`, `honeybadger`, `bugsnag`

---

### `lograge`

| | |
|---|---|
| **Version** | `0.14.0` |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/lograge](https://rubygems.org/gems/lograge) |

Reduces Rails' multi-line log output to a single structured log line per request.

**Used in:** `config/application.rb` — structured request logging with Logstash formatter in production.

**Alternatives:** `semantic_logger`, custom log subscriber

---

### `logstash-event`

| | |
|---|---|
| **Version** | `1.2.02` |
| **Release date** | 2014 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/logstash-event](https://rubygems.org/gems/logstash-event) |

Provides the Logstash JSON event format used by Lograge.

**Used in:** `config/application.rb` — `config.lograge.formatter = Lograge::Formatters::Logstash.new` in production.

**Alternatives:** `lograge` built-in JSON formatter

---

### `slack-notifier`

| | |
|---|---|
| **Version** | `2.4.0` |
| **Release date** | 2020 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/slack-notifier](https://rubygems.org/gems/slack-notifier) |

Sends messages to Slack via incoming webhooks.

**Used in:** `SlackServices::SignalRackAttack`, `SlackServices::SignalContribution`, and other Slack service classes — alert and moderation notifications to Slack channels.

**Alternatives:** Slack Bolt SDK, direct Slack API HTTP calls

---

## Utilities

### `whenever`

| | |
|---|---|
| **Version** | `1.0.0` |
| **Release date** | 2020 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/whenever](https://rubygems.org/gems/whenever) |

Ruby DSL for writing and deploying cron jobs.

**Used in:** `config/scheduler/` (development.rb, preprod.rb, prod.rb) — scheduled recurring tasks (e.g., cleanup jobs, data sync).

**Alternatives:** Sidekiq Cron, `clockwork`, Heroku Scheduler

---

### `ffi`

| | |
|---|---|
| **Version** | `1.17.2` *(Gemfile: `~> 1.17`)* |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/ffi](https://rubygems.org/gems/ffi) |

Foreign Function Interface for Ruby — loads and calls native C libraries.

**Used in:** Transitive dependency for `sassc` and `ruby-stemmer` native extensions; pinned for cross-platform compatibility across multiple architectures.

**Alternatives:** N/A (low-level dependency)

---

### `rspec_api_documentation`

| | |
|---|---|
| **Version** | `6.1.0` |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rspec_api_documentation](https://rubygems.org/gems/rspec_api_documentation) |

Generates API documentation from RSpec acceptance tests.

**Used in:** API spec suite — documents REST API endpoints from integration tests.

**Alternatives:** Swagger/OpenAPI (`rswag`), `apipie-rails`

---

## Development & Code Quality *(dev)*

### `bullet`

| | |
|---|---|
| **Version** | `8.0.8` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/bullet](https://rubygems.org/gems/bullet) |

Detects N+1 queries and unused eager loading during development.

**Used in:** Development environment — logs or raises on query performance issues.

**Alternatives:** `prosopite`, `active_record_doctor`

---

### `rubocop`

| | |
|---|---|
| **Version** | `1.81.1` |
| **Release date** | 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rubocop](https://rubygems.org/gems/rubocop) |

Ruby static code analyser and formatter based on the Ruby Style Guide.

**Used in:** Development — code style enforcement and linting.

**Alternatives:** `standard`, `reek`

---

### `rubocop-rspec`

| | |
|---|---|
| **Version** | `3.7.0` |
| **Release date** | 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rubocop-rspec](https://rubygems.org/gems/rubocop-rspec) |

RuboCop extension with RSpec-specific cops.

**Used in:** Development — linting RSpec test files for best practices.

**Alternatives:** N/A (extends RuboCop)

---

### `rubocop-rails`

| | |
|---|---|
| **Version** | `2.33.4` |
| **Release date** | 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rubocop-rails](https://rubygems.org/gems/rubocop-rails) |

RuboCop extension with Rails-specific cops.

**Used in:** Development — enforces Rails conventions alongside base RuboCop rules.

**Alternatives:** N/A (extends RuboCop)

---

### `rubocop-performance`

| | |
|---|---|
| **Version** | `1.26.0` |
| **Release date** | 2025 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rubocop-performance](https://rubygems.org/gems/rubocop-performance) |

RuboCop extension with performance-focused cops.

**Used in:** Development — flags potentially slow Ruby patterns.

**Alternatives:** N/A (extends RuboCop)

---

### `dotenv-rails`

| | |
|---|---|
| **Version** | `3.1.8` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/dotenv-rails](https://rubygems.org/gems/dotenv-rails) |

Loads environment variables from a `.env` file into `ENV` in development.

**Used in:** Development and test environments — local environment variable management.

**Alternatives:** `figaro`, manual shell exports

---

### `foreman`

| | |
|---|---|
| **Version** | `0.90.0` |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/foreman](https://rubygems.org/gems/foreman) |

Process manager that runs multiple processes defined in a `Procfile`.

**Used in:** Development — starts web server, worker, and other processes together.

**Alternatives:** `overmind`, `hivemind`

---

### `spring`

| | |
|---|---|
| **Version** | `2.1.1` *(Gemfile: `~> 2.1.0`)* |
| **Release date** | 2021 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/spring](https://rubygems.org/gems/spring) |

Rails application preloader that keeps the app running in the background to speed up test/command startup.

**Used in:** Development — faster `rails` and `rspec` command execution.

**Alternatives:** `bootsnap` (different approach), Zeus

---

### `spring-commands-rspec`

| | |
|---|---|
| **Version** | `1.0.4` |
| **Release date** | 2014 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/spring-commands-rspec](https://rubygems.org/gems/spring-commands-rspec) |

Adds `rspec` as a Spring command so tests run with Spring's preloaded environment.

**Used in:** Development — faster RSpec test startup via Spring.

**Alternatives:** N/A (Spring plugin)

---

### `rails-controller-testing`

| | |
|---|---|
| **Version** | `1.0.5` |
| **Release date** | 2020 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rails-controller-testing](https://rubygems.org/gems/rails-controller-testing) |

Restores `assigns` and `assert_template` helpers removed from Rails 5+ for controller tests.

**Used in:** Development/test — legacy controller test helpers.

**Alternatives:** Request specs with `rspec-rails`

---

## Testing *(test)*

### `rspec-rails`

| | |
|---|---|
| **Version** | `7.1.1` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rspec-rails](https://rubygems.org/gems/rspec-rails) |

RSpec testing framework integration for Rails.

**Used in:** `spec/` directory — primary test framework for all unit, integration, and request specs.

**Alternatives:** Minitest, Test::Unit

---

### `shoulda-matchers`

| | |
|---|---|
| **Version** | `6.5.0` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/shoulda-matchers](https://rubygems.org/gems/shoulda-matchers) |

One-liner RSpec matchers for common Rails model and controller tests.

**Used in:** Model and controller specs — validates associations, validations, and more concisely.

**Alternatives:** Custom RSpec matchers

---

### `factory_bot_rails`

| | |
|---|---|
| **Version** | `4.11.1` *(Gemfile: `~> 4`)* |
| **Release date** | 2018 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/factory_bot_rails](https://rubygems.org/gems/factory_bot_rails) |

Test fixture replacement with a clean DSL for defining model factories.

**Used in:** `spec/factories/` — creates test objects in RSpec examples.

**Alternatives:** `fabrication`, Rails fixtures

---

### `timecop`

| | |
|---|---|
| **Version** | `0.9.10` |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/timecop](https://rubygems.org/gems/timecop) |

Provides helpers for time travel and time freezing in tests.

**Used in:** Specs — freezing or travelling time to test time-dependent behaviour.

**Alternatives:** `ActiveSupport::Testing::TimeHelpers`, `ice_age`

---

### `webmock`

| | |
|---|---|
| **Version** | `3.25.1` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/webmock](https://rubygems.org/gems/webmock) |

Stubs and mocks HTTP requests in tests.

**Used in:** Specs — prevents real HTTP calls to external APIs during tests.

**Alternatives:** `vcr`, `fakeweb`

---

### `fakeredis`

| | |
|---|---|
| **Version** | `0.9.2` |
| **Release date** | 2022 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/fakeredis](https://rubygems.org/gems/fakeredis) |

In-memory Redis driver for tests, eliminating the need for a real Redis server.

**Used in:** Test environment — substitutes Redis for Sidekiq and caching in specs.

**Alternatives:** `mock_redis`, `redis-client` with a test driver

---

### `super_diff`

| | |
|---|---|
| **Version** | `0.16.0` |
| **Release date** | 2024 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/super_diff](https://rubygems.org/gems/super_diff) |

Replaces RSpec's default differ with a more readable, coloured diff for complex objects.

**Used in:** Test output — clearer failure messages for hashes, arrays, and nested structures.

**Alternatives:** RSpec built-in differ

---

### `rspec-parameterized`

| | |
|---|---|
| **Version** | `2.0.0` |
| **Release date** | 2023 (approximate) |
| **Changelog / Rubygems** | [rubygems.org/gems/rspec-parameterized](https://rubygems.org/gems/rspec-parameterized) |

Adds parameterised (table-driven) test syntax to RSpec.

**Used in:** Specs — data-driven tests with multiple input/output combinations in a table format.

**Alternatives:** `shared_examples` with `let`, manual `[].each` loops

---
