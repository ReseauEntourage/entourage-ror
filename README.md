[![Build Status](https://travis-ci.org/ReseauEntourage/entourage-ror.svg?branch=master)](https://travis-ci.org/ReseauEntourage/entourage-ror)
[![Coverage Status](https://coveralls.io/repos/ReseauEntourage/entourage-ror/badge.svg?branch=master&service=github)](https://coveralls.io/github/ReseauEntourage/entourage-ror?branch=master)

# Prerequisites

Ruby 2.6.5
Rails 4.2.11

rbenv or rvm recommanded

# Update API

```
aglio -i apiary.apib -o public/developer.html
```

### Install aglio:

```
npm install -g aglio
```

# Environment variables

Some environment variables are needed to run this application.

```bash
DATABASE_URL=postgres://<user>:<pass>@localhost:5432 # The database URL
HOST=entourage.localhost # The Host that is used in Nginx routing if multiple app exists behind the same port
```

You can source these environment variables froms a `.env` file.

To get started : `cp .env.dist .env` and fill in the missing informations !

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
bin/d rake db:migrate
bin/d foreman start web
```

You can run below commands prepending `bin/d` to them and it will run in the
container !

# Local install

## Resolve dependencies and database migration :

```bash
gem install 'bundler:~>1'
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
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

# Accessing admin panel

To access the admin panel, you need to set an entry in your `/etc/hosts` :

```
127.0.0.1 admin.entourage.localhost
```

You also need to create an admin user :

```bash
echo "UserServices::PublicUserBuilder.new(params: {phone: '+33606060606', admin: true}, community: Community.new(:entourage)).create(sms_code: '123456')" | rails c
```

Then, browse `admin.entourage.localhost:<port>`.

# Rspec tests

Setup database :

```
rake db:drop db:create db:migrate RAILS_ENV=test
```

Run tests with

```
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

# Profiling

## rbspy

To profile a request (in a puma worker):
```bash
bin/d -u root -- rbspy record --pid $(cat tmp/puma.pid) --subprocesses --file flamegraph
```

# Dredd tests (Deprecated)

Test the API documentation compliance with [Dredd](https://github.com/apiaryio/dredd)

## Install Dredd:
```
$ npm install -g dredd
```

## Setup database for Dredd tests:
- Reset DB to reset id sequence
- Populate database with Dredd specific seeds (cf file ./db/seeds/dredd.rb)

```
$ rake db:reset dredd:seeds
```

### rake dredd:seeds task description:
- Removes all newsletter subscriptions
- Removes all users
- Generates the dredd user

## Run Dredd:

```
$ rake dredd
```

## Dredd config

Dredd options are listed in dredd.yml file

# Guard

## Guard Rspec (default)

Launch automatically tests with:

```
$ bundle exec guard
```

## Guard Api blueprint

Launch automatically dredd and aglio (static documentation generation) with:

```
$ bundle exec guard -g apib
```

## Redirection to app stores :
In order to redirect a mobile to the application from a SMS, we redirect toward a page on the website :

http://api.entourage.social/store_redirection

* If you visit this page from an iOS device you will be redirected to the Appstore
* If you visit this page from an Android device you will be redirected to the PlayStore

The logic and URL for the store can be found here :
https://s3-eu-west-1.amazonaws.com/entourage-ressources/store_redirection.html
