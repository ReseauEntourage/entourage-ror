json.encounters do
  json.id @encounter.id
  json.date @encounter.date
  json.latitude @encounter.latitude
  json.longitude @encounter.longitude
  json.user_id @encounter.user.id
  json.user_name @encounter.user.first_name
  json.street_person_name @encounter.street_person_name
  json.message @encounter.message
  json.voice_message @encounter.voice_message_url
end