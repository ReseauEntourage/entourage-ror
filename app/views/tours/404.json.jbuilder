json.error do
  json.status 404
  json.message "Could not find tour with id #{@id}"
end
