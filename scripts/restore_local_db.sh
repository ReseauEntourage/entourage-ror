#!/usr/bin/env bash
set -e

echo "CLOSE ALL PROGRAMS USING THE DATABASE : Ruby web server, SQL client, etc"

echo "snapshot production DB"
heroku pg:backups capture -a entourage-back
echo "Reset DB"
rake db:drop db:create
echo "Download DB from production"
curl -o tmp/db.dump `heroku pg:backups public-url -a entourage-back`
echo "Restore DB"
pg_restore -h localhost -d entourage-dev tmp/db.dump
echo "Restore test db"
RAILS_ENV=test rake db:migrate
echo "Clean files"
rm tmp/db.dump
