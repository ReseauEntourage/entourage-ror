#!/usr/bin/env bash

bin/rake db:drop db:create db:migrate
bin/rake fake_data:users[10_000]
