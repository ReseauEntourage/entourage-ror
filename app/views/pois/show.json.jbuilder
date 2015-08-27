json.poi do
	json.id @poi.id
	json.name @poi.name
	json.description @poi.description
	json.longitude @poi.longitude
	json.latitude @poi.latitude
	json.adress @poi.adress
	json.phone @poi.phone
	json.website @poi.website
	json.email @poi.email
	json.audience @poi.audience
	json.validated @poi.validated
	json.category do
	  json.id @poi.category.id
    json.name @poi.category.name
	end
end
