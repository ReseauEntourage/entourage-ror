
# Prerequisites

Ruby 3.4.12
Rails 7.1.0

rbenv or rvm recommanded


# Environment variables

Some environment variables are needed to run this application.

```bash
DATABASE_URL=postgres://<user>:<pass>@localhost:5432 # The database URL
HOST=entourage.localhost # The Host that is used in Nginx routing if multiple app exists behind the same port
```

You can source these environment variables from a `.env` file.

To get started : `cp .env.dist .env` and fill in the missing informations!

## Mobile API keys

`Api::ApplicationKey` (`app/services/api/application_key.rb`) validates the `X-API-KEY` header sent by the mobile apps. Neither the key values nor their app versions are in the source code: they live in two env vars, each a comma-separated list of `version:key` pairs for that platform.

| Variable | Content |
|---|---|
| `API_KEYS_IOS` | comma-separated `version:key` pairs for all valid iOS API keys, e.g. `9.0.0:44b2f3f3e7fd9b9c391a2f06,10.0.0:a5cc26940b6f91fa8e462a3f` |
| `API_KEYS_ANDROID` | same, for Android |

From version `9.0.0` onward (see `HMAC_SINCE` in `application_key.rb`), a key is also given that platform's `HMAC_SECRET_*` — see below.

⚠️ **These must be set in every environment that accepts mobile traffic** (including `development`/`test` if you exercise those flows) — without them, no iOS/Android request can be authenticated at all.

To add a new app version, generate a key and append a `version:key` entry at the end of the list — order doesn't matter, but never remove an entry a shipped app still relies on:

```bash
ruby -e "require 'securerandom'; puts SecureRandom.hex(12)"
```

## HMAC request signing (anti-bot)

Two variables protect the account creation endpoint (`POST /api/v1/users`) against bots.
Each mobile app signs its requests with a shared secret; the backend verifies the signature.

| Variable | Used by |
|---|---|
| `HMAC_SECRET_ANDROID` | Android app (`BuildConfig.HMAC_SECRET`) |
| `HMAC_SECRET_IOS` | iOS app (`ApiKeys.plist → HmacSecret`) |

Generate a secret with:

```bash
ruby -e "require 'securerandom'; puts SecureRandom.hex(32)"
```

**The check is mandatory.** Every `POST /api/v1/users` request must carry a valid signature, computed with the API key's `hmac_secret`. There is no bypass: a client whose key has no `hmac_secret` configured (any app version below 9.0.0, `web`, or a debug key) is rejected with `MISSING_SIGNING_KEY`, and a request without valid `X-Request-Timestamp` / `X-Request-Signature` headers is rejected with `MISSING_SIGNATURE` / `EXPIRED_SIGNATURE` / `INVALID_SIGNATURE`.

⚠️ **`HMAC_SECRET_ANDROID` and `HMAC_SECRET_IOS` must be set in every environment that needs to accept account creation** (including `development`, if you test signup locally) — without them, even v9.0.0+ clients are rejected and account creation is entirely unavailable.

To create an account locally without a real mobile app, sign the request yourself:

```bash
ruby -e "
  require 'openssl'
  secret = ENV.fetch('HMAC_SECRET_IOS')
  timestamp = Time.now.to_i
  phone = '+33612345678'
  signature = OpenSSL::HMAC.base64digest('SHA256', secret, \"POST\n/api/v1/users\n#{timestamp}\n#{phone}\")
  puts \"X-Request-Timestamp: #{timestamp}\"
  puts \"X-Request-Signature: #{signature}\"
"
```

Note that the `.env` file is used for all Rails environments. If you want to target only one (e.g. the `development` environment but not the `test` environment), use a file named `.env.{environment_name}` (e.g `.env.development`).

You will find more informations about this in the `dotenv` gem's [README](https://github.com/bkeepers/dotenv/blob/master/README.md).

# Docker

You can run this application using Docker.

There is a wrapper, `bin/d`, that allows you to run command in the correct
container.

Example :

```bash
bin/d # Shows help
bin/d up # Setup needed containers
# bin/d gem install bundler -v '2.2.16'
# bin/d bundle install
bin/d bundle exec rake db:migrate
bin/d foreman start web
```

You can run below commands prepending `bin/d` to them and it will run in the
container !

*Note:* after modifying the `Dockerfile`, you might need to run

```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml build spring
```

This commands mirrors what happens in `bin/docker/up` to build the `dev` variant of the Docker image.
TODO: there has to be a simple way to do this. We should update the `bin/docker/*` script as needed or at least create one for this.

# Docker - Tests

```bash
RAILS_ENV=test bin/d bundle exec rake db:drop db:create db:migrate
RAILS_ENV=test bin/d bundle exec rspec
```

# Docker - Psql

If you want to connect directly to docker psql, use:

```bash
docker-compose exec --env RAILS_ENV=development postgresql psql postgres://guest:guest@postgresql:5432/entourage-dev
```

See `docker-compose.yml` for more details.

# Local install

## Resolve dependencies and database migration

```bash
gem install 'bundler:~>1'
bundle install
bundle exec rake db:create
bundle exec rake db:migrate # if any trouble with postgis, please see Postgis section below
```

## Launch application

```bash
bundle exec rails server
```

Or, with `foreman` :

```bash
# gem install foreman
foreman start web
```

# Running scheduled jobs

Scheduled jobs documentation is accessible [here](config/scheduler/Jobs.md)

# Configure job worker

```bash
bundle exec sidekiq -c 5 -q mailers -q default -q broadcast -q denorm
```

# Accessing admin panel

To access the admin panel, you need to set an entry in your `/etc/hosts` :

```bash
127.0.0.1 admin.entourage.localhost
```

You also need to create an admin user :

```bash
echo "UserServices::PublicUserBuilder.new(params: {phone: '+33606060606', admin: true}, community: Community.new(:entourage)).create(sms_code: '123456')" | rails c
```

Then, browse `admin.entourage.localhost:<port>`.

# Rspec tests

Setup database :

```bash
rake db:drop db:create db:migrate RAILS_ENV=test
```

Run tests with

```bash
$ rspec
```

# AI assistant

The Entourage AI assistant reads Local and acts in the name of a user through the routes of `/api/v1/assistant` (`app/controllers/api/v1/assistant`). They are not the routes of the apps: no token in the parameters, no effect on the last sign in, the Salesforce synchronization or the session tracking, and the parameters are never logged nor sent to Sentry.

Every request carries the API key of the assistant in `X-API-KEY` (`ASSISTANT_API_KEY`) and the token of the user in `Authorization: Bearer <token>`. Anonymous, deleted, blocked and anonymized accounts are refused. The JSON is camelCase, the ids are strings, a missing information is `null`. The contract is agreed with the assistant (change `add-assistant-social-link-tools` of entourage-specs).

## Reads (`GET`)

Each answer is built by a presenter with a closed list of fields (`app/services/assistant/presenters`), never by a serializer of the app.

| Route | What it returns |
|---|---|
| `identity` | `id` (uuid), first name and city of the user |
| `profile` | what the user declared: `city`, `distanceKm`, `goal` (`seek-help`, `give-help`, `both`), `interests`, `availabilities` (`"monday 09:00-12:00"`), `gender` (`woman`, `man`, `null`) |
| `activity` | `upcomingOutings` and `pastOutings` (briefs), `groups`, `helpPosts` (requests and offers published), `connectionsCount` (discussions started, never a message) |
| `referent` | the dedicated contact (the moderator the app shows), or `{ referent: null }` |
| `outings` | search with `OutingsServices::Finder`: `city`, `interest`, `days` (ISO numbers 1..7, 1 = Monday), `size`, `reserved_female=true`, `chatting=true`. Briefs: `id, title, startsAt, place, participantsCount, placeLimit, reservedFemale, format`. 10 outings, 30 when `size` is given (Local does not filter on the size: the assistant does). An outing reserved to women is only returned when asked. Without `city` or with the one of the profile, the search starts from the address of the user; another city is geocoded (`PLACE_NOT_FOUND` if unknown) |
| `outings/:id` | the flat sheet: `id, title, description, startsAt, endsAt, durationMinutes, place, organizerName, participantsCount, placeLimit, format, reservedFemale, subjectId, meetingType`. `subjectId` is the subject of the anonymous measures |
| `outings/:id/participants` | `count` and `people[{ id, displayName, roles }]`: what the app shows to a member |
| `outings/:id/participation` | `{ registered, attended }`; 404 when the outing is unknown or hidden from the user |
| `help_requests`, `help_offers` | search: `city`, `category`. `items[{ id, title, category }]`, never the text nor the author |
| `help_categories` | the categories of help of the app |
| `groups/:id` | `{ id, name }` |

## Actions (`POST`)

An action needs an `Idempotency-Key` header (the id of the preview that the person confirmed) and `ASSISTANT_ACTIONS_ENABLED=true`. It uses the services of the app with the model of the user, so the validations and the effects are the ones of the app (neither the place limit nor `reserved_female` refuse a registration there, so they do not here). `Assistant::ActionRunner` runs it once per key: a replay returns the first answer (`Idempotent-Replayed: true`), the same key for another request is refused (422), a request still running answers 409, a failed action is not replayed, and a row that stays `processing` for more than 2 minutes is abandoned (410 `ACTION_EXPIRED`, never run under this key: the person asks a new action with a new key).

| Route | Body | Action |
|---|---|---|
| `outings/:id/register`, `outings/:id/unregister` | `{}` | registers, cancels the registration |
| `outings` | `title`, `description`, `startsAt`, `endsAt` (ISO 8601), `place` (text), `reservedFemale` | creates an outing. `place` is geocoded (`400 PLACE_NOT_FOUND`) |
| `help_requests`, `help_offers` | `title`, `category`, `description`, `recipientConsentObtained` (requests) | publishes from the address of the user. A request without consent is `suspended` (moderation), as in the app |
| `members/:id/messages` | `message` | first message to a member, in their private conversation |
| `outings/:id/organizer_messages` | `message` | message to the organizer |
| `outings/:id/discussion_messages` | `message` | message in the discussion of an outing the user is registered to (403 `NOT_A_MEMBER`) |
| `groups/:id/join_requests` | | joins a group (immediate in the app) |
| `alerts` | `audience` (`referent`, `team`), `message`, `kind` (`safety_signal`, `negative_feedback`, `handover`) | message to the team on Slack (`SLACK_SIGNAL`). `referent` names the dedicated contact when there is one that Slack can mention. Default kind: `handover` for the referent, `safety_signal` for the team. `status: not_delivered` when Slack fails |

Errors are `{ "error": { "code": ..., "message": ..., "reasons": ... } }`: `INVALID_API_KEY` (401), `INVALID_TOKEN` (401), `ANONYMOUS_ACCOUNT` (403), `NOT_A_MEMBER` (403), `ACTIONS_DISABLED` (503), `IDEMPOTENCY_KEY_REQUIRED` (400), `IDEMPOTENCY_KEY_REUSED` (422), `ACTION_IN_PROGRESS` (409), `ACTION_EXPIRED` (410), `INVALID_PARAMS` (400), `PLACE_NOT_FOUND` (400 on an action, 404 on a read), `NOT_FOUND` (404), `NOT_REGISTERED` (404), `RECIPIENT_UNAVAILABLE` (404), `CANNOT_JOIN`, `CANNOT_LEAVE`, `CANNOT_PUBLISH`, `CANNOT_SEND` (400, with the reasons of the app) and `ACTION_FAILED` (500). The assistant reads the `code`: it retries twice with the same key on 409 `ACTION_IN_PROGRESS`, 429, 5xx and network errors, never on `ACTIONS_DISABLED` nor `ACTION_FAILED`.

Each action is a row of `assistant_actions` (user, key, type, digest of the request, status, result, subject): the team finds from it what the assistant did, and the other members see no difference. The result only holds identifiers and statuses, never a text. The rows are deleted with the account.

## Variables

| Variable | Content |
|---|---|
| `ASSISTANT_API_KEY` | key of the assistant for every route above (see its section if your branch has it) |
| `ASSISTANT_ACTIONS_ENABLED` | `true` to let the assistant act. **False by default**: every action answers 503 `ACTIONS_DISABLED`, the reads are not affected |
| `ASSISTANT_API_URL` | **base URL** of the assistant (without `/api`): the events go to `<base>/api/v1/product-events`, the measures are read from `<base>/api/v1/measures` |
| `ASSISTANT_SERVICE_KEY` | key of Local for these two routes, sent in `X-Service-Key`. Distinct from `ASSISTANT_API_KEY`. Without `ASSISTANT_API_URL` and this key, nothing is sent and nothing fails |

When an account is deleted or anonymized (`deleted` becoming true, whatever the path: app, back-office, `User#anonymize!`), `AssistantAccountObserver` deletes its `assistant_actions` and queues `AssistantAccountEventJob`, which `POST`s `{ event: "account.deleted" | "account.anonymized", product: "local", userId: <uuid>, occurredAt }`, and nothing else about the person. Sidekiq retries it for weeks on network errors, 5xx and 429; a 400, 401 or 403 is reported to Sentry once and not retried.

The back-office shows the anonymous measures of an event (`admin/outings/:id/measures`, linked from the list): Local reads the aggregate from the assistant and only shows the distribution above its threshold, "too few responses" otherwise. Local keeps and receives no individual answer.

Personal data for the DPO: the text of a city other than the one of the profile, and the place of an outing created by the assistant, are sent to the geocoder of the app (`Assistant::PlaceGeocoder`).

## Deployment order and rollback

1. Deploy the migration of `assistant_actions` (additive, one table).
2. Deploy the code with `ASSISTANT_ACTIONS_ENABLED` false: the reads and the account event are active, the actions refuse.
3. Set `ASSISTANT_API_URL` and `ASSISTANT_SERVICE_KEY` once the assistant is deployed with its receiving route.
4. Switch the actions on.
5. Rollback: set `ASSISTANT_ACTIONS_ENABLED` to false (no deployment). Unset the two other variables to stop the events and the reading of the measures. The table can stay.

# Database dump

## Import a database dump

```bash
bin/d db-restore path/to/snapshot.dump
```

## Generate a stripped database dump from production data

You need to have access to the `entourage-back` Heroku application.

```bash
bin/d db-pull entourage-back
bin/d rake db:strip
bin/d db-dump path/to/snapshot.dump
```

# Postgis

If you have any trouble with `postgis` during `db:migrate`, please install `postgis`:

Using PSQL 12

```bash
sudo apt install postgis postgresql-12-postgis-3
sudo apt-get install postgresql-12-postgis-3-scripts
```

Using PSQL 11

```bash
sudo apt install postgis postgresql-11-postgis-3
sudo apt-get install postgresql-11-postgis-3-scripts
```

Then, activate `postgis` in your database (**DO NOT INSTALL it in the database called `postgres`**):

```bash
psql
\c entourage-dev
entourage-dev=# CREATE EXTENSION postgis;
entourage-dev=# SELECT PostGIS_version();
```

# API documentation

1. open in a browser: `public/doc/api/index.html`
2. or open directly URL : https://admin.entourage.social/doc/api/index.html

# Profiling

## rbspy

To profile a request (in a puma worker):
```bash
bin/d -u root -- rbspy record --pid $(cat tmp/puma.pid) --subprocesses --file flamegraph
```

# Dredd tests (Deprecated)

Test the API documentation compliance with [Dredd](https://github.com/apiaryio/dredd)

## Install Dredd

```bash
$ npm install -g dredd
```

## Setup database for Dredd tests:
- Reset DB to reset id sequence
- Populate database with Dredd specific seeds (cf file ./db/seeds/dredd.rb)

```bash
$ rake db:reset dredd:seeds
```

### rake dredd:seeds task description:
- Removes all newsletter subscriptions
- Removes all users
- Generates the dredd user

## Run Dredd

```bash
$ rake dredd
```

## Dredd config

Dredd options are listed in dredd.yml file

# Guard

## Guard Rspec (default)

Launch automatically tests with:

```bash
$ bundle exec guard
```

## Guard Api blueprint

Launch automatically dredd and aglio (static documentation generation) with:

```bash
$ bundle exec guard -g apib
```

## Redirection to app stores :
In order to redirect a mobile to the application from a SMS, we redirect toward a page on the website :

http://api.entourage.social/store_redirection

* If you visit this page from an iOS device you will be redirected to the Appstore
* If you visit this page from an Android device you will be redirected to the PlayStore

The logic and URL for the store can be found here :
https://s3-eu-west-1.amazonaws.com/entourage-ressources/store_redirection.html
