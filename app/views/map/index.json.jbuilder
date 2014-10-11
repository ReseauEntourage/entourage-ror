json.categories @categories do |category|
  json.id category.id
  json.name category.name
end

json.pois @pois do |poi|
  json.id poi.id
  json.name poi.name
  json.description poi.description
  json.longitude poi.longitude
  json.latitude poi.latitude
  json.adress poi.adress
  json.phone poi.phone
  json.website poi.website
  json.email poi.email
  json.audience poi.audience
  json.category_id poi.category_id
end

json.encounters @encounters do |encounter|
  json.id encounter.id
  json.date encounter.date
  json.latitude encounter.latitude
  json.longitude encounter.longitude
  json.user_id encounter.user.id
  json.user_name encounter.user.first_name
  json.street_person_name encounter.street_person_name
  json.message encounter.message
  json.voice_message encounter.voice_message_url
end