#!/bin/bash

login=$(echo "$IRAISER_CREDENTIALS" | cut -d: -f1)
password=$(echo "$IRAISER_CREDENTIALS" | cut -d: -f2)

curl 'https://entourage.iraiser.eu/manager.php/jauth/login/in' \
  --data "login=$login&password=$password" \
  --cookie-jar iraiser_cookie

curl 'https://entourage.iraiser.eu/manager.php/manager/donations/exportCsv' \
  --cookie iraiser_cookie \
  -o export.csv

rails runner scripts/import_iraiser_csv.rb export.csv

rm iraiser_cookie export.csv
