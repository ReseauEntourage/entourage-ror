#!/usr/bin/env bash
set -e

echo "CLOSE ALL PROGRAMS USING THE DATABASE : Ruby web server, SQL client, etc"
lsof -t -i tcp:3000 | xargs kill -9

echo "snapshot preproduction DB"
heroku pg:backups capture -a entourage-back
echo "Reset DB"
bundle exec rake db:drop db:create
echo "Download DB from preproduction"
curl -o tmp/db.dump `heroku pg:backups public-url -a entourage-back`
echo "Restore DB"
pg_restore -h localhost -d entourage-dev tmp/db.dump
echo "Restore test db"
RAILS_ENV=test bundle exec rake db:migrate
echo "Clean files"

