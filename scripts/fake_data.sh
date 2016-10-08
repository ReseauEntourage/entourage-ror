#!/usr/bin/env bash
set -e


USERS_NB=1000
TOURS_NB=$(($USERS_NB * 5))
TOUR_JOIN_REQUESTS_NB=$(($USERS_NB * 5))
TOUR_POINTS_NB=$(($USERS_NB * 5))
ENTOURAGES_NB=$(($USERS_NB * 5))
ENTOURAGES_JOIN_REQUESTS_NB=$(($USERS_NB * 5))


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