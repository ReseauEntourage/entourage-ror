#!/usr/bin/env bash

# deprecated pour l'import en local de la db

set -e

PROD="entourage-back"
STAGING="entourage-back-preprod"
LOCAL_DB_NAME=entourage-dev

if [[ $1 == "prod" ]]; then
	current=$PROD
else
  echo "To run on production DB, use ./scripts/restore_local_db.sh prod"
	current=$STAGING
fi

echo "CLOSE ALL PROGRAMS USING THE DATABASE : Ruby web server, SQL client, etc"
lsof -t -i tcp:3000 | xargs kill -9
pkill rails || true

echo "Drop local DB"
dropdb $LOCAL_DB_NAME || true
echo "Pull remote DB"
heroku pg:pull DATABASE $LOCAL_DB_NAME -a $current
echo "Restore test db"
RAILS_ENV=test bundle exec bin/rake db:migrate
