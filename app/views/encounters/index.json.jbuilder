json.encounters @encounters do |encounter|
  json.id encounter.id
  json.date encounter.date
  json.latitude encounter.latitude
  json.longitude encounter.longitude
  json.user_id encounter.user_id
  json.street_person_name encounter.street_person_name
  json.message encounter.message
end