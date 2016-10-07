#!/usr/bin/env bash

USERS_NB=10_000
ENTOURAGES_NB=50_000

bin/rake db:drop db:create db:migrate
bin/rake fake_data:users[$USERS_NB]
bin/rake fake_data:entourages[$ENTOURAGES_NB,$USERS_NB]
