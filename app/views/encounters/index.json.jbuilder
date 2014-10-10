json.encounters @encounters do |encounter|
  json.id encounter.id
  json.created_at encounter.created_at
  json.location encounter.location
  json.user_id encounter.user_id
  json.street_person_name encounter.street_person_name
  json.message encounter.message
end