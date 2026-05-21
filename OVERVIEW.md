# backend (entourage-ror) — overview

> Added by the `entourage_specs` meta-repo. The submodule's own canonical README lives at `README.md`.

The Ruby on Rails 7.1 API powering the entire LOCAL product. Source of truth for users, actions (entourages, contributions, solicitations, outings), neighbourhoods, messaging, POIs and admin moderation. Serves three frontends (iOS, Android, webapp) and is where every external integration for LOCAL is centralised. Hosted on Heroku as multiple Procfile-driven dynos.

## Interactions

```
              ┌────────────┐  ┌─────────────┐  ┌────────────┐
              │   iOS app  │  │ Android app │  │   webapp   │
              └──────┬─────┘  └──────┬──────┘  └─────┬──────┘
                     │ HTTPS REST    │              │
                     └───────────────┴──────────────┘
                                      │
                                      ▼
              ┌────────────────────────────────────────────┐
              │ entourage-ror   (Rails 7.1 + PostGIS + Sidekiq)
              │ api.entourage.social/api/v1/                │
              └────────────────────────────────────────────┘
                                      │
   ┌────────┬────────┬────────┬───────┼────────┬────────┬────────┬─────────┐
   ▼        ▼        ▼        ▼       ▼        ▼        ▼        ▼         ▼
PostgreSQL Redis  Salesforce OpenAI  Mailjet Slack   APNS / RPush  AWS S3  Soliguide
+ PostGIS  + Sidekiq                                + Firebase             Google Maps
                                                                            Vonage / Nexmo
```

- **Mobile / web clients**: REST API (`/api/v1/`).
- **Salesforce**: OAuth + sync via `restforce ~> 7.6` (`SalesforceJob`).
- **OpenAI**: moderation and translation assistants via `ruby-openai` (`OpenaiRequestJob`).
- **Mailjet**: transactional email via the `mailjet` gem.
- **Slack**: signal commands, unblock and offensive webhooks; bidirectional via `slack-notifier`.
- **Push notifications**: APNS via `apnotic` + `rpush ~> 9.1`; Firebase as fallback.
- **AWS S3**: avatar and image buckets via `aws-sdk-s3 ~> 1` (also `aws-sdk-sns ~> 1`).
- **Google APIs**: Maps, Calendar / Gmail / Meet for the "Bonnes Ondes" smalltalk feature via `google-api-client ~> 0.53`.
- **Soliguide**: POI database integration.
- **SMS**: routed via Slack or Vonage/Nexmo (`SMS_PROVIDER`).
- **GLOBAL/entourage-tasks Lambdas**: read the same PostgreSQL for daily aggregations (user-engagement, user-scorings, salesforce_connect, inapp-notifs).

## Installing / scripts

```bash
gem install bundler:'~>1'
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rails server                 # localhost:3000
foreman start web                        # Procfile: Puma + 2 Sidekiq workers
bundle exec sidekiq -c 5 -q ... -q ...   # manual worker
```

Docker:

```bash
bin/d up                           # bring up Postgres + Redis + Sidekiq + Puma
bin/d bundle exec rake db:migrate
bin/d foreman start web
```

Heroku Procfiles are split per-environment / per-role: `Procfile`, `Procfile.api-prod`, `Procfile.api-preprod`, `Procfile.backoffice-prod`, `Procfile.backoffice-preprod`.

Sidekiq jobs of note: `SalesforceJob`, `OpenaiRequestJob`, `SmsTalkAutoStartChatMessageJob`, `PushNotificationTriggerJob`, `NotificationJob`, `ConversationMessageBroadcastJob`, `ConversationMessageBroadcastDeNormJob`. Cron handled by the `whenever` gem (and Supercronic in Docker).

## External libraries

- **Framework**: `rails ~> 7.1`, `pg ~> 1.1`, `activerecord-postgis-adapter ~> 9.0`.
- **Async / jobs**: `sidekiq ~> 8`, `sidekiq-cron`, `sidekiq-unique-jobs`, `redis ~> 4`.
- **Integrations**: `restforce ~> 7.6` (Salesforce), `ruby-openai`, `slack-notifier`, `mailjet`, `rpush ~> 9.1.0`, `apnotic`, `nexmo`.
- **AWS / Google**: `aws-sdk-s3 ~> 1`, `aws-sdk-sns ~> 1`, `google-api-client ~> 0.53`.
- **Serializers / models**: `active_model_serializers ~> 0.10`, `ancestry`, `acts-as-taggable-on ~> 12`, `json-schema ~> 2.8.1`.
- **Security**: `bcrypt ~> 3`.
- **Logging / monitoring**: `lograge`, `logstash-event`, `sentry-ruby`.
- **Test**: `rspec-rails`, `shoulda-matchers`, `factory_bot_rails ~> 4`, `webmock`, `fakeredis`.

## Used technologies

- **Language**: Ruby 3.2.0.
- **Framework**: Rails 7.1.
- **Datastore**: PostgreSQL 11+ with PostGIS (geographic queries).
- **Queue**: Sidekiq + Redis.
- **API**: REST v1 (JSON), versioned controllers; Dredd-validated.
- **Admin panel**: custom Rails admin on `admin.entourage.localhost`.
- **CI/CD**: CircleCI (`circle.yml`) + Dredd API contract tests (`dredd/`).
- **Deployment**: Heroku, multiple Procfiles (api-prod, api-preprod, backoffice-prod, backoffice-preprod). Dockerfile available (Ruby 2.7.2 base in legacy Dockerfile + Supercronic).

## Secrets (`.env.dist` / Heroku config vars)

`DATABASE_URL`,
`HOST`, `API_HOST`, `ADMIN_HOST`, `MOBILE_HOST`, `WEBSITE_URL`, `WEBSITE_APP_URL`, `COMMUNITY`, `DEEPLINK_SCHEME`, `ENTOURAGE_USER_PHONE`,
`SALESFORCE_LOGIN_URL`, `SALESFORCE_CLIENT_ID`, `SALESFORCE_CLIENT_SECRET`, `SALESFORCE_REDIRECT_URI`, `SALESFORCE_USERNAME`, `SALESFORCE_PASSWORD`,
`OPENAI_API_KEY`, `OPENAI_API_ASSISTANT_ID`, `OPENAI_API_OFFENSE_ASSISTANT_ID`,
`SLACK_APP_VERIFICATION_TOKEN`, `SLACK_APP_WEBHOOKS`, `SLACK_SIGNAL`, `SLACK_UNBLOCK_WEBHOOK`, `SLACK_OFFENSIVE_WEBHOOK`, `SLACK_WEBHOOK_URL`,
`SMS_PROVIDER`, `SMS_PROVIDER_SECONDARY`, `SMS_SENDER_NAME`,
`MAILJET_API_KEY`, `MAILJET_SECRET_KEY`, `ENABLE_MAILJET`,
`APNS8_TEAM_ID`, `APNS8_BUNDLE_ID`, `APNS8_APN_KEY`, `APNS8_APN_KEY_ID`,
`GOOGLE_API_KEY`, `GOOGLE_MAPS_KEY`, `BONNES_ONDES_SERVICE_ACCOUNT` (JSON), `BONNES_ONDES_EMAIL_ACCOUNT`,
`ENTOURAGE_AWS_SECRET_ACCESS_KEY`, `ENTOURAGE_AWS_ACCESS_KEY_ID`, `ENTOURAGE_AVATARS_BUCKET`, `ENTOURAGE_IMAGES_BUCKET`,
`POI_FORM_SECRET_TOKEN`, `SOLIGUIDE_API_KEY`.

Plus `config/secrets.yml` for the Rails secret key base (development/test hardcoded, production from `ENV`), and APNS certificates under `certificates/`.
