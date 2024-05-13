
# Prerequisites

Ruby 3.1.0
Rails 7.0.8.1

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

# Install

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
RAILS_ENV=test rake db:drop db:create db:migrate
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

## Redirection to app stores :
In order to redirect a mobile to the application from a SMS, we redirect toward a page on the website :

http://api.entourage.social/store_redirection

* If you visit this page from an iOS device you will be redirected to the Appstore
* If you visit this page from an Android device you will be redirected to the PlayStore

The logic and URL for the store can be found here :
https://s3-eu-west-1.amazonaws.com/entourage-ressources/store_redirection.html
