[![Build Status](https://semaphoreci.com/api/v1/projects/e06001fd-34da-4414-9789-e09e3f28c67a/623094/badge.svg)](https://semaphoreci.com/vdaubry/entourage-ror)
[![Coverage Status](https://coveralls.io/repos/ReseauEntourage/entourage-ror/badge.svg?branch=master&service=github)](https://coveralls.io/github/ReseauEntourage/entourage-ror?branch=master)

# Prerequisites

Ruby 2.2.3
Rails 4.2

rbenv or rvm recommanded

# Update API

```
aglio -i apiary.apib -o public/developer.html
```


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

## Redirection to app stores :
In order to redirect a mobile to the application from a SMS, we redirect toward a page on the website :

http://entourage-back.herokuapp.com/store_redirection

* If you visit this page from an iOS device you will be redirected to the Appstore
* If you visit this page from an Android device you will be redirected to the PlayStore

The logic and URL for the store can be found here :
/app/views/home/store_redirection.html.erb
