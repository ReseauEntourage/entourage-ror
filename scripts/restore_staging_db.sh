#!/usr/bin/env bash

# deprecated pour faire un dump de la db de prod pour le mettre en préprod

set -e

echo "Snapshot production db"
heroku pg:backups capture --app entourage-back

echo "Restore production db in staging"
heroku pg:backups restore `heroku pg:backups public-url --app entourage-back` DATABASE -a entourage-back-preprod --confirm entourage-back-preprod

echo "Run migration"
heroku run rake db:migrate -a entourage-back-preprod
heroku run rake data_migration:migration_jobs -a entourage-back-preprod
heroku run rake db:remove_old_points -a entourage-back-preprod
