#!/bin/bash

# se connecte au compte iraiser pour faire un exportCsv

login=$(echo "$IRAISER_CREDENTIALS" | cut -d: -f1)
password=$(echo "$IRAISER_CREDENTIALS" | cut -d: -f2)

function log {
  echo $@ >&2
}

log "[*] Obtaining cookie"
curl 'https://entourage.iraiser.eu/manager.php/jauth/login/in' \
  --data "login=$login&password=$password" \
  --cookie-jar iraiser_cookie \
  --silent

function download {
  local output=$1
  local date_start=$2
  local date_end=$3

  log "[*] Downloading $output"
  curl 'https://entourage.iraiser.eu/manager.php/manager/donations/exportCsv' \
    --data "date_start=${date_start}&date_end=${date_end}" -X GET --get \
    --cookie iraiser_cookie \
    --output $output \
    --write-out '%{filename_effective}%{stderr}--> filename=%{filename_effective} status=%{http_code} size=%{size_download} time=%{time_total}s\n' \
    --silent
}

# The export times out if it's too large, so we segment by quarter to reduce each
# file's size.
files=()
for year in $(seq 2017 $(date +%Y)); do
  files+=($(download "${year}_Q1_export.csv" 01/01/$year 31/03/$year))
  files+=($(download "${year}_Q2_export.csv" 01/04/$year 30/06/$year))
  files+=($(download "${year}_Q3_export.csv" 01/07/$year 30/09/$year))
  files+=($(download "${year}_Q4_export.csv" 01/10/$year 31/12/$year))
done

log "[*] Concatenating files"
found_header=false
for file in ${files[@]}; do
  if [[ ! -f $file ]]; then
    log "[!] File $file does not exist. File skipped."
    continue
  fi

  file_size=$(( $(wc -c < $file) ))
  file_start=$(head -c 13 $file | ruby -e 'print STDIN.read.inspect[1..-2]')

  if [[ $file_size == 1 && $file_start == "\n" ]]; then
    log "[i] Empty file $file. File skipped."
    rm $file
    continue
  fi

  # Compare beginning of file with expected CSV header
  if [[ $file_start != "donator_dear;" ]]; then
    log "[!] Unexpected file start \"$file_start\" in $file. File skipped."
    # Note: we don't remove unexpected files
    continue
  fi

  # Get the header from the first valid file
  if [[ $found_header != true ]]; then
    log "[*] Using header from $file"
    head -n1 $file > export.csv
    found_header=true
  fi

  log "--> $file"
  # Exclude the header from the each file
  tail -n+2 $file >> export.csv
  rm $file
done

rails runner scripts/import_iraiser_clean_csv.rb export.csv export-clean.csv
rails runner scripts/import_iraiser_csv.rb export-clean.csv

rm iraiser_cookie export.csv export-clean.csv
