
# Prerequisites

Ruby 3.2.0
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
