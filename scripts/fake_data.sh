#!/usr/bin/env bash
set -e

USERS_NB=10_000
TOURS_NB=50_000
TOUR_JOIN_REQUESTS_NB=50_000
TOUR_POINTS_NB=50_000
ENTOURAGES_NB=50_000
ENTOURAGES_JOIN_REQUESTS_NB=50_000


echo "starting at :"
date

bin/rake db:drop db:create db:migrate
bin/rake fake_data:users[$USERS_NB]
bin/rake fake_data:tours[$TOURS_NB,$USERS_NB]
bin/rake fake_data:tours_join_requests[$TOUR_JOIN_REQUESTS_NB,$TOURS_NB,$USERS_NB]
bin/rake fake_data:tour_points[$TOUR_POINTS_NB,$TOURS_NB]
bin/rake fake_data:entourages[$ENTOURAGES_NB,$USERS_NB]
bin/rake fake_data:entourages_join_requests[$ENTOURAGES_JOIN_REQUESTS_NB,$TOURS_NB,$USERS_NB]

echo "ended at :"
date