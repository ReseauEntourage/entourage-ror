#!/usr/bin/env bash
set -e

PROD="entourage-back"
STAGING="entourage-back-preprod"
LOCAL_DB_NAME=entourage-dev

if [ $1 == "prod" ]; then
	current=$PROD
else
	current=$STAGING
fi

echo "CLOSE ALL PROGRAMS USING THE DATABASE : Ruby web server, SQL client, etc"
lsof -t -i tcp:3000 | xargs kill -9
pkill Valentina || true

echo "snapshot remote DB $current"
heroku pg:backups capture -a $current
echo "Reset DB"
bundle exec rake db:drop db:create
echo "Download DB dump from $current"
curl -o tmp/db.dump `heroku pg:backups public-url -a $current`
echo "Restore DB"
pg_restore -h localhost -d $LOCAL_DB_NAME tmp/db.dump || true
echo "Restore test db"
RAILS_ENV=test bundle exec rake db:migrate