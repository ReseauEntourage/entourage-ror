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