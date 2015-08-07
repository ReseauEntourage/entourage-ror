# Prerequisites

Ruby 2.0.0
Rails 4.2

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
- Populate database with Dredd specific seeds (cf file ./db/seeds/dredd.rb)

```
$ rake db:reset dredd:seeds
```

### rake dredd:seeds task description:
Removes all newsletter subscriptions
Removes all users
Generates the dredd user

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