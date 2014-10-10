json.array! @pois do |poi|
	json.name poi.name
	json.description poi.description
	json.poi_type poi.poi_type
	json.longitude poi.longitude
	json.latitude poi.latitude
	json.adress poi.adress
	json.phone poi.phone
	json.website poi.website
	json.email poi.email
	json.audience poi.audience
end