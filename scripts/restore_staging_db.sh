#!/usr/bin/env bash
set -e

#echo "Install heroku toolbelt on dyno"
#curl -s https://s3.amazonaws.com/assets.heroku.com/heroku-client/heroku-client.tgz | tar xz
#PATH="heroku-client/bin:$PATH"

echo "Snapshot production db"
heroku pg:backups capture --app entourage-back

echo "Restore production db in staging"
heroku pg:backups restore `heroku pg:backups public-url --app entourage-back` DATABASE -a entourage-back-preprod --confirm entourage-back-preprod

echo "Run migration"
heroku run rake db:migrate -a entourage-back-preprod
heroku run rake data_migration:migration_jobs -a entourage-back-preprod
heroku run rake db:remove_old_points -a entourage-back-preprod
