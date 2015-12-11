#!/usr/bin/env bash
set -e

echo "CLOSE ALL PROGRAMS USING THE DATABASE : Ruby web server, SQL client, etc"

echo "Reset DB"
rake db:drop db:create
echo "Download DB from preprod"
curl -o db.dump `heroku pg:backups public-url -a entourage-back-preprod`
echo "Restore DB"
pg_restore -h localhost -d entourage-dev tmp/db.dump
echo "Clean files"
rm db.dump