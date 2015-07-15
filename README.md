# Prerequisites

Ruby 2.0.0
Rails 4.1.1

rbenv or rvm recommanded

# Resolve dependencies and run server

```
$ gem install bundler
$ bundle install --without production
$ bundle exec rake db:migrate
$ bundle exec rails server
```

# Rspec tests

Run tests with 

```
$ rspec
```

# Dredd tests

Test the API documentation compliance with [Dredd](https://github.com/apiaryio/dredd)

## Install Dredd:
```
$ npm install -g dredd
```

## Setup database for Dredd tests:
- Reset DB to reset id sequence
- Run migrations to set database schema
- Populate database with Dredd specific seeds (cf file ./db/seeds/dredd.rb)

```
$ rake db:drop db:migrate dredd:seeds
```

### rake dredd:seeds task description:
Removes all newsletter subscriptions
Removes all users
Generates the dredd user

## Run Dredd:

```
$ dredd
```

## Dredd config

Dredd options are listed in dredd.yml file