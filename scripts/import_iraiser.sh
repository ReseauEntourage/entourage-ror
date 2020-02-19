#!/bin/bash

login=$(echo "$IRAISER_CREDENTIALS" | cut -d: -f1)
password=$(echo "$IRAISER_CREDENTIALS" | cut -d: -f2)

echo "[*] Obtaining cookie"
curl 'https://entourage.iraiser.eu/manager.php/jauth/login/in' \
  --data "login=$login&password=$password" \
  --cookie-jar iraiser_cookie \
  --silent

# The export times out if it's too large, so we segment by year to reduce each
# file's size.
files=()
for year in $(seq 2017 $(date +%Y)); do
  output="${year}_export.csv"
  echo "[*] Downloading $output"
  curl 'https://entourage.iraiser.eu/manager.php/manager/donations/exportCsv' \
    --data "date_start=01/01/$year&date_end=31/12/$year" -X GET --get \
    --cookie iraiser_cookie \
    --output $output \
    --silent
  files+=($output)
done

echo "[*] Concatenating files"
# Get the header from the first file
head -n1 ${files[0]} > export.csv
for file in ${files[@]}; do
  # Exclude the header from the each file
  tail -n+2 $file >> export.csv
  rm $file
done

rails runner scripts/import_iraiser_csv.rb export.csv

rm iraiser_cookie export.csv
